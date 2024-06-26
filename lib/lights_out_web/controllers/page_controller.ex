defmodule LightsOutWeb.PageController do
  use LightsOutWeb, :controller
  alias LightsOut.Game

  def home(conn, _params) do
    difficulty_options = ["Easy": 3, "Medium": 10, "Hard": 20]
    default_difficulty = 10

    new_game_form = %{
      "difficulty" => 10,
      "player_name" => ""
    }

    existing_game_form = %{
      "room_code" => "",
      "player_name" => ""
    }

    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home,
      layout: false,
      new_game_form: new_game_form,
      existing_game_form: existing_game_form,
      difficulty_options: difficulty_options,
      default_difficulty: default_difficulty
    )
  end

  def new(conn, params) do
    difficulty = String.to_integer(params["difficulty"])
    name = params["player_name"]
    code = Game.Server.start(difficulty, name)
    redirect(conn, to: ~p"/game/#{code}?player=#{name}")
  end

  def join(conn, params) do
    redirect(conn, to: ~p"/game/#{params["room_code"]}?player=#{params["player_name"]}")
  end
end
