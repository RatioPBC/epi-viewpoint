defmodule EpiViewpointWeb.UploadedFileTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpoint.Tempfile
  alias EpiViewpointWeb.UploadedFile

  describe "from_plug_upload" do
    @tag :tmp_dir
    test "creates a new ImportedFile with a sanitized filename and the contents of the file", %{tmp_dir: tmp_dir} do
      path = Tempfile.write_csv!("file contents", tmp_dir)

      UploadedFile.from_plug_upload(%{path: path, filename: "   somé//crazy\nfilename"})
      |> assert_eq(%{file_name: "somécrazy filename", contents: "file contents"})
    end
  end
end
