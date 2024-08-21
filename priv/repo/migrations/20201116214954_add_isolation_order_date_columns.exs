defmodule EpiViewpoint.Repo.Migrations.AddIsolationOrderDateColumns do
  use Ecto.Migration

  def change do
    alter table(:case_investigations) do
      add :isolation_order_clearance_sent_date, :date
      add :isolation_order_sent_date, :date
    end
  end
end
