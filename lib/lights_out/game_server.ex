defmodule LightsOut.Game.Server do
  use GenServer
  alias LightsOut.Game

  def start_link(size, difficulty, player_name) do
    # 4 character room code
    room_code = String.duplicate("ABCDEFGHIJKLMNOPQRSTUVWXYZ", 2) |> String.graphemes() |> Enum.shuffle() |> Enum.take(4) |> Enum.join()

    game = Game.new_game(size, difficulty, player_name)
    state = %{game: game, room_code: room_code}
    GenServer.start_link(__MODULE__, state, name: via_tuple(room_code))
    room_code
  end

  def get_game(room_code) do
    GenServer.call(via_tuple(room_code), :get_game)
  end

  defp via_tuple(room_code), do: {:via, Registry, {Game.Registry, room_code}}

  @impl true
  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_game, _from, state) do
    {:reply, state.game, state}
  end
end
