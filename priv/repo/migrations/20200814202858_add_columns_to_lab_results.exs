defmodule EpiViewpoint.Repo.Migrations.AddColumnsToLabResults do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :request_facility_code, :string
      add :request_facility_name, :string
    end
  end
end
