defmodule Epicenter.Tempfile do
  def write!(contents, extension) do
    name = Ecto.UUID.generate() <> "." <> extension
    path = Path.join(System.tmp_dir!(), name)
    File.write!(path, contents)
    path
  end
end
