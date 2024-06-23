defmodule LightsOutWeb.GameLive.Index do
  use LightsOutWeb, :live_view
  alias LightsOut.Game

  @impl true
  def mount(%{"code" => code, "player" => player}, _session, socket) do
    if connected?(socket) do
      if Game.Server.does_exist?(code) do
        Game.Server.subscribe(code)
        Game.Server.add_player(code, player)

        socket
        |> assign(code: code, game: Game.Server.get_game(code), player: player)
        |> ok()
      else
        socket
        |> put_flash(:error, "Room #{code} not found")
        |> ok()
      end
    else
      {:ok, socket}
    end
  end

  # def terminate(_reason, socket) do
  #   if socket.assigns[:player] do
  #     Game.Server.remove_player(socket.assigns.player)
  #   end
  # end

  @impl true
  def handle_event("toggle-cell", %{"x" => x, "y" => y}, socket) do
    Game.Server.toggle(socket.assigns.code, {String.to_integer(x), String.to_integer(y)})
    socket |> noreply()
  end

  @impl true
  def handle_info({"game-updated", game}, socket) do
    socket
    |> assign(game: game)
    |> noreply()
  end
end
