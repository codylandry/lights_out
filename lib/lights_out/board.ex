defmodule LightsOut.Game.Board do

  # not all random setups are solvable, so we will start with an empty board and randomly toggle 'difficulty' number of cells to
  # ensure that the game is solvable.  The default difficulty is 10.
  def new(size \\ 5, difficulty \\ 5) do
    board = blank(size)
    Enum.reduce(1..difficulty, board, fn _, board -> toggle(board, random_cell(board)) end)
  end

  # toggle the cell and its neighbors, returns an updated board
  def toggle(board, {x, y}) do
    # update the cell
    board = Map.update!(board, {x, y}, fn state -> not state end)

    # update the neighbors
    # for each neighbor, get the opposite state of the cell and create a map
    # with the neighbor as the key and the opposite state as the value
    Enum.reduce(neighbors(board, {x, y}), board, fn {x, y}, board ->
      Map.update!(board, {x, y}, fn state -> not state end)
    end)
  end

  def is_solved?(board) do
    Enum.all?(Map.values(board), fn state -> not state end)
  end

  # builds a map where each key is a tuple representing a cell in the board, ie {x, y}
  # and the value is a boolean representing the state of the cell, ie true for on and false for off, default is false
  def blank(size) do
    for x <- 1..size, y <- 1..size, into: %{} do
      {{x, y}, false}
    end
  end

  def random_cell(board) do
    Enum.random(Map.keys(board))
  end

  def neighbors(board, {x, y}) do
    size = size(board)
    [
      {x, y + 1},
      {x, y - 1},
      {x + 1, y},
      {x - 1, y}
    ]
    |> Enum.filter(fn {x, y} -> x > 0 and x <= size and y > 0 and y <= size end)
  end

  def size(board) do
    board
    |> Map.keys
    |> Enum.map(fn {x, _} -> x end)
    |> Enum.max()
  end

  # log out a visual representation of the board using X for on and O for off
  # as a markdown table
  def log(board) do
    size = size(board)

    # Print the top border of the table
    IO.puts("|" <> Enum.join(List.duplicate("---", size), "|") <> "|")

    for y <- 1..size do
      # Print each row with "|" as cell separators
      for x <- 1..size do
        IO.write("| ")
        IO.write(if Map.get(board, {x, y}), do: "X", else: "O")
        IO.write(" ")
      end
      # Print the right border of the table and start a new line
      IO.puts("|")

      # Print the border between rows
      IO.puts("|" <> Enum.join(List.duplicate("---", size), "|") <> "|")
    end

    board
  end
end
