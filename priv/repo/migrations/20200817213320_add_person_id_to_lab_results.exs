defmodule Epicenter.Repo.Migrations.AddPersonIdToLabResults do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :person_id, references(:people)
    end
  end
end
