defmodule LightsOutWeb.GameLive.Index do
  use LightsOutWeb, :live_view
  alias LightsOut.Game

  @impl true
  def mount(%{"code" => code, "player" => player}, _session, socket) do
    if connected?(socket) do
      # ensures `terminate` runs when the process shuts down
      Process.flag(:trap_exit, true)

      if Game.Server.does_exist?(code) do
        Game.Server.subscribe(code)
        Game.Server.add_player(code, player)

        socket
        |> assign(code: code, game: Game.Server.get_game(code), player: player)
        |> ok()
      else
        socket
        |> put_flash(:error, "Room #{code} not found")
        |> redirect(to: ~p"/")
        |> ok()
      end
    else
      socket
      |> assign(code: code, game: Game.new_game(0, player), player: player)
      |> ok()
    end
  end

  @impl true
  def terminate(_reason, socket) do
    if socket.assigns[:player] do
      Game.Server.remove_player(socket.assigns.code, socket.assigns.player)
    end
  end

  @impl true
  def handle_event("toggle-cell", %{"x" => x, "y" => y}, socket) do
    if Game.current_player(socket.assigns.game) != socket.assigns.player do
      socket
      |> put_flash(:error, "It's not your turn")
      |> noreply()
    else
      Game.Server.toggle(socket.assigns.code, {String.to_integer(x), String.to_integer(y)})
      Game.Server.next_turn(socket.assigns.code)

      socket
      |> push_event("toggle", %{})
      |> noreply()
    end
  end

  @impl true
  def handle_info({"game-updated", game}, socket) do
    socket
    |> assign(game: game)
    |> flash_if_won(game)
    |> noreply()
  end

  defp flash_if_won(socket, game) do
    if Game.is_solved?(game) do
      socket
      |> put_flash(:info, "Congratulations! You won!")
    else
      socket
    end
  end

  defp player_class(assigns, player) do
    this_player = assigns.player
    current_player = Game.current_player(assigns.game)

    case player do
      ^this_player -> "text-red-900"
      ^current_player -> "text-green-900"
      _ -> "text-white"
    end
  end
end
