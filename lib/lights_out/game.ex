defmodule LightsOut.Game do
  alias LightsOut.Game.Board

  defstruct players: [],
            board: %{},
            turn: 0,
            winner: nil

  def new_game(size, difficulty, initial_player_name) do
    %LightsOut.Game{
      players: [initial_player_name],
      board: Board.new(size, difficulty)
    }
  end

  def current_player(game) do
    Enum.at(game.players, rem(game.turn, length(game.players)))
  end

  def toggle(game, {x, y}) do
    %{game | board: Board.toggle(game.board, {x, y})}
  end

  def is_solved?(game) do
    Board.is_solved?(game.board)
  end

  def add_player(game, player_name) do
    updated_players = game.players ++ [player_name]

    unique_players =
      updated_players
      |> Enum.into(MapSet.new())
      |> Enum.into([])

    %{game | players: unique_players}
  end

  def remove_player(game, player_name) do
    %{game | players: Enum.reject(game.players, &(&1 == player_name))}
  end

  def next_turn(game) do
    %{game | turn: game.turn + 1}
  end
end
