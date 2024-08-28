defmodule EpiViewpoint.Tempfile do
  def write_csv!(contents, tmp_dir) do
    write_file!(contents, tmp_dir, "csv")
  end

  def write_ndjson!(contents, tmp_dir) do
    write_file!(contents, tmp_dir, "ndjson")
  end

  # sobelow_skip ["Traversal.FileModule"]
  defp write_file!(contents, tmp_dir, extension) do
    path = tmp_dir |> Path.join(Ecto.UUID.generate() <> ".#{extension}")
    File.write!(path, contents)
    path
  end
end
