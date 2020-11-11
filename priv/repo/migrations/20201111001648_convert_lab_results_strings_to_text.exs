defmodule Epicenter.Repo.Migrations.ConvertLabResultsStringsToText do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      modify :request_accession_number, :text, from: :string
      modify :request_facility_code, :text, from: :string
      modify :request_facility_name, :text, from: :string
      modify :result, :text, from: :string
      modify :source, :text, from: :string
      modify :test_type, :text, from: :string
      modify :tid, :text, from: :string
    end
  end
end
