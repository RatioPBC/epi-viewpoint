defmodule Epicenter.Repo.Migrations.AddPersonIdToPhones do
  use Ecto.Migration

  def change do
    alter table(:phones) do
      add :person_id, references(:people, type: :uuid)
    end
  end
end
