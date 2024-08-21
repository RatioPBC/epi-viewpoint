defmodule EpiViewpoint.Repo.Migrations.AddTidToLabResults do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :tid, :string
    end
  end
end
