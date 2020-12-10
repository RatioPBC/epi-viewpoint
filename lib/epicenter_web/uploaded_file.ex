defmodule EpicenterWeb.UploadedFile do
  # sobelow_skip ["Traversal.FileModule"]
  def from_plug_upload(%{path: path, filename: file_name}) do
    %{file_name: Zarex.sanitize(file_name), contents: File.read!(path)}
  end
end
