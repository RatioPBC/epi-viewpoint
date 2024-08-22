defmodule EpiViewpoint.Repo.Migrations.CreateRevisions do
  use Ecto.Migration

  def change() do
    create table(:revisions, primary_key: false) do
      add :after_change, :map, null: false
      add :author_id, :binary_id, null: false
      add :before_change, :map, null: false
      add :change, :map, null: false
      add :changed_id, :string, null: false
      add :changed_type, :string, null: false
      add :id, :binary_id, primary_key: true, null: false
      add :reason_action, :string, null: false
      add :reason_event, :string, null: false
      add :seq, :bigserial, null: false
      add :tid, :string

      timestamps(updated_at: false)
    end
  end
end
