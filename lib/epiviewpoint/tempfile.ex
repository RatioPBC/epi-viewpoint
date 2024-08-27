defmodule EpiViewpoint.Tempfile do
  # sobelow_skip ["Traversal.FileModule"]
  def write_csv!(contents) do
    write_file!(contents, "csv")
  end

  def write_ndjson!(contents) do
    write_file!(contents, "ndjson")
  end

  defp write_file!(contents, extension) do
    path = System.tmp_dir!() |> Path.join(Ecto.UUID.generate() <> ".#{extension}")
    File.write!(path, contents)
    path
  end
end
