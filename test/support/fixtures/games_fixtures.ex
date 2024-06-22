defmodule LightsOut.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LightsOut.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(attrs \\ %{}) do
    {:ok, game} =
      attrs
      |> Enum.into(%{
        code: "some code"
      })
      |> LightsOut.Games.create_game()

    game
  end
end
