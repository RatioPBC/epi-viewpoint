defmodule Epicenter.Repo.Migrations.AddClinicalStatusDataToCaseInvestigation do
  use Ecto.Migration

  def change do
    alter table(:case_investigations) do
      add :clinical_status, :string
      add :symptom_onset_date, :date
      add :symptoms, {:array, :string}
    end
  end
end
