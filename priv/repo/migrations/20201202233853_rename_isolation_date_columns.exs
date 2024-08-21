defmodule EpiViewpoint.Repo.Migrations.RenameIsolationDateColumns do
  use Ecto.Migration

  def change do
    rename table(:case_investigations), :isolation_monitoring_ended_on,
      to: :isolation_monitoring_ends_on

    rename table(:case_investigations), :isolation_monitoring_started_on,
      to: :isolation_monitoring_starts_on
  end
end
