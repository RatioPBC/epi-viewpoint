defmodule EpiViewpoint.Tempfile do
  def write_csv!(contents) do
    write_file!(contents, "csv")
  end

  def write_ndjson!(contents) do
    write_file!(contents, "ndjson")
  end

  # sobelow_skip ["Traversal.FileModule"]
  defp write_file!(contents, extension) do
    path = System.tmp_dir!() |> Path.join(Ecto.UUID.generate() <> ".#{extension}")
    File.write!(path, contents)
    path
  end
end
