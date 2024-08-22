defmodule EpiViewpointWeb.UploadedFileTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpoint.Tempfile
  alias EpiViewpointWeb.UploadedFile

  describe "from_plug_upload" do
    test "creates a new ImportedFile with a sanitized filename and the contents of the file" do
      path = Tempfile.write_csv!("file contents")

      UploadedFile.from_plug_upload(%{path: path, filename: "   somé//crazy\nfilename"})
      |> assert_eq(%{file_name: "somécrazy filename", contents: "file contents"})
    end
  end
end
