defmodule Pairs do
  def run() do
    """

    ██████╗   █████╗  ██╗ ██████╗  ███████╗
    ██╔══██╗ ██╔══██╗ ██║ ██╔══██╗ ██╔════╝
    ██████╔╝ ███████║ ██║ ██████╔╝ ███████╗
    ██╔═══╝  ██╔══██║ ██║ ██╔══██╗ ╚════██║
    ██║      ██║  ██║ ██║ ██║  ██║ ███████║
    ╚═╝      ╚═╝  ╚═╝ ╚═╝ ╚═╝  ╚═╝ ╚══════╝

    ---- use spaces to separate names ----
    """
    |> IO.puts()

    pairings(get_people("Who is sticky?"), get_people("Who is not sticky?"))
  end

  def get_people(prompt),
    do: IO.gets("#{prompt} ") |> String.split(~r|\s+|, trim: true) |> Enum.map(&String.trim/1)

  def pairings(sticky, not_sticky) do
    IO.puts("")

    reduce_pairs(Enum.shuffle(sticky), Enum.shuffle(not_sticky), [])
    |> Enum.sort()
    |> Enum.join("\n")
    |> IO.puts()

    IO.puts("")

    okay? = IO.gets("Is this pairing okay? [Y/n] ")

    if String.trim(okay?) == "n",
      do: pairings(sticky, not_sticky),
      else: :ok
  end

  def reduce_pairs([], [], result),
    do: result

  def reduce_pairs([a1 | a], [], result),
    do: reduce_pairs(a, [], [pair(a1) | result])

  def reduce_pairs([], [b1 | [b2 | b]], result),
    do: reduce_pairs([], b, [pair(b1, b2) | result])

  def reduce_pairs([], [b], result),
    do: reduce_pairs([], [], [pair(b) | result])

  def reduce_pairs([a1 | a], [b1 | b], result),
    do: reduce_pairs(a, b, [pair(a1, b1) | result])

  def pair(a),
    do: "#{a} solos"

  def pair(a, b),
    do: [a, b] |> Enum.sort() |> Enum.join(" + ")
end

Pairs.run()
