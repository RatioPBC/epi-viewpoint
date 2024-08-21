defmodule EpiViewpoint.Repo.Migrations.ConvertCaseInvestigationsStringsToText do
  use Ecto.Migration

  def change do
    alter table(:case_investigations) do
      modify :clinical_status, :text, from: :string
      modify :discontinue_reason, :text, from: :string
      modify :interview_proxy_name, :text, from: :string
      modify :name, :text, from: :string
      modify :symptoms, {:array, :text}, from: {:array, :text}
      modify :tid, :text, from: :string
    end
  end
end
