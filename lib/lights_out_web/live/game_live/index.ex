defmodule LightsOutWeb.GameLive.Index do
  use LightsOutWeb, :live_view
  alias LightsOut.Game

  @impl true
  def handle_params(%{"code" => code}, _url, socket) do
    if Game.Server.does_exist?(code) do
      socket
      |> assign(code: code, game: Game.Server.get_game(code))
      |> noreply()
    else
      socket
      |> put_flash(:error, "Room #{code} not found")
      |> noreply()
    end
  end

  @impl true
  def handle_event("toggle-cell", %{"x" => x, "y" => y}, socket) do
    Game.Server.toggle(socket.assigns.code, {String.to_integer(x), String.to_integer(y)})
    socket |> noreply()
  end
end
