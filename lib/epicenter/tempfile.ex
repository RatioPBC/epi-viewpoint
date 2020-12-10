defmodule Epicenter.Tempfile do
  # sobelow_skip ["Traversal.FileModule"]
  def write_csv!(contents) do
    path = System.tmp_dir!() |> Path.join(Ecto.UUID.generate() <> ".csv")
    File.write!(path, contents)
    path
  end
end
