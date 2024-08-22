defmodule EpiViewpoint.Repo.Migrations.CreateImportedFiles do
  use Ecto.Migration

  def change do
    create table(:imported_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :seq, :integer
      add :tid, :string
      add :file_name, :string
      add :contents, :text

      timestamps()
    end
  end
end
