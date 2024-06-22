defmodule LightsOut.Game.Server do
  use GenServer
  alias LightsOut.Game

  # client

  def start_link(size, difficulty, player_name) do
    # 4 character room code
    room_code = create_room_code()
    game = Game.new_game(size, difficulty, player_name)
    state = %{game: game, room_code: room_code}
    GenServer.start_link(__MODULE__, state, name: via_tuple(room_code))
    room_code
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
    |> reply(:ok)
  end

  defp ok(state), do: {:ok, state}
  defp reply(state, response), do: {:reply, response, state}
  defp noreply(state), do: {:noreply, state}
end
