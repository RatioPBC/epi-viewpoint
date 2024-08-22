defmodule EpiViewpoint.Repo.Migrations.AddContacts do
  use Ecto.Migration

  def change do
    create table(:exposures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :relationship_to_case, :string, null: false
      add :household_member, :boolean, null: false, default: false
      add :under_18, :boolean, null: false, default: false
      add :most_recent_date_together, :date, null: false

      add :exposed_person_id, references(:people, on_delete: :restrict, type: :binary_id),
        null: false

      add :exposing_case_id,
          references(:case_investigations, on_delete: :delete_all, type: :binary_id),
          null: false

      add :seq, :bigserial
      add :tid, :string

      timestamps()
    end
  end
end
