defmodule EpiViewpoint.Repo.Migrations.AddResultToLabResults do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :result, :string
    end
  end
end
