defmodule EpiViewpoint.Repo.Migrations.ConvertImportedFilesStringsToText do
  use Ecto.Migration

  def change do
    alter table(:imported_files) do
      modify :file_name, :text, from: :string
      modify :tid, :text, from: :string
    end
  end
end
