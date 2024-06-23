defmodule LightsOut.Game.Server do
  use GenServer
  alias Phoenix.PubSub
  alias LightsOut.Game

  # client

  def start(difficulty, player_name) do
    {:ok, _pid, room_code} =
      DynamicSupervisor.start_child(
        Game.Supervisor,
        {Game.Server, [difficulty, player_name]}
      )

    room_code
  end

  def start_link([difficulty, player_name]) do
    room_code = create_room_code()
    game = Game.new_game(difficulty, player_name)

    state = %{
      game: game,
      room_code: room_code
    }

    {:ok, pid} = GenServer.start_link(__MODULE__, state, name: via_tuple(room_code))
    {:ok, pid, room_code}
  end

  def does_exist?(room_code) do
    case Registry.lookup(Game.Registry, room_code) do
      [_resp] -> true
      [] -> false
    end
  end

  def get_game(room_code) do
    GenServer.call(via_tuple(room_code), :get_game)
  end

  def toggle(room_code, {_x, _y} = cell) do
    GenServer.call(via_tuple(room_code), {:toggle, cell})
  end

  def add_player(room_code, player_name) when is_binary(player_name) do
    GenServer.cast(via_tuple(room_code), {:add_player, player_name})
  end

  def remove_player(room_code, player_name) when is_binary(player_name) do
    GenServer.cast(via_tuple(room_code), {:remove_player, player_name})
  end

  def next_turn(room_code) do
    GenServer.cast(via_tuple(room_code), :next_turn)
  end

  defp via_tuple(room_code), do: {:via, Registry, {Game.Registry, room_code}}

  defp create_room_code do
    code =
      String.duplicate("ABCDEFGHIJKLMNOPQRSTUVWXYZ", 2)
      |> String.graphemes()
      |> Enum.shuffle()
      |> Enum.take(4)
      |> Enum.join()

    if does_exist?(code) do
      create_room_code()
    end

    code
  end

  def pubsub_topic(room_code) do
    "game:#{room_code}"
  end

  def subscribe(room_code) do
    PubSub.subscribe(LightsOut.PubSub, pubsub_topic(room_code))
  end

  # server

  @impl true
  def init(state) do
    state |> ok()
  end

  @impl true
  def handle_call(:get_game, _from, state) do
    reply(state, state.game)
  end

  @impl true
  def handle_call({:toggle, cell}, _from, state) do
    state
    |> Map.put(:game, Game.toggle(state.game, cell))
    |> broadcast()
    |> reply(:ok)
  end

  @impl true
  def handle_cast({:add_player, player_name}, state) do
    state
    |> Map.put(:game, Game.add_player(state.game, player_name))
    |> broadcast()
    |> noreply()
  end

  @impl true
  def handle_cast({:remove_player, player_name}, state) do
    new_state =
      state
      |> Map.put(:game, Game.remove_player(state.game, player_name))
      |> broadcast()

    new_state
    |> broadcast()
    |> timeout_if_empty_game()
  end

  @impl true
  def handle_cast(:next_turn, state) do
    state
    |> Map.put(:game, Game.next_turn(state.game))
    |> broadcast()
    |> noreply()
  end

  # when we timeout due to 0 players in the game, terminate the process
  @impl true
  def handle_info(:timeout, state) do
    DynamicSupervisor.terminate_child(Game.Supervisor, self())
    stop(state, :reason)
  end

  # If the game is empty (0 players), set a timeout.
  # if we don't get a message in that time, this will fire the handle_info(:timeout, state)
  # callback, where we terminate the process
  defp timeout_if_empty_game(state) do
    if length(state.game.players) == 0 do
      {:noreply, state, 30000}
    else
      {:noreply, state}
    end
  end

  # publish changes to game state so liveviews can consume the changes to update local state
  defp broadcast(state) do
    PubSub.broadcast(
      LightsOut.PubSub,
      pubsub_topic(state.room_code),
      {"game-updated", state.game}
    )

    state
  end

  defp ok(state), do: {:ok, state}
  defp reply(state, response), do: {:reply, response, state}
  defp noreply(state), do: {:noreply, state}
  defp stop(state, reason), do: {:stop, reason, state}
end
