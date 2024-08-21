defmodule EpiViewpoint.Repo.Migrations.AddClinicalStatusExposedOnSymptomsToContactInvestigation do
  use Ecto.Migration

  def change do
    alter table(:contact_investigations) do
      add :clinical_status, :text
      add :exposed_on, :date
      add :symptoms, {:array, :text}
    end
  end
end
