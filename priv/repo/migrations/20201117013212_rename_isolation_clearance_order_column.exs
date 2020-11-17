defmodule Epicenter.Repo.Migrations.RenameIsolationClearanceOrderColumn do
  use Ecto.Migration

  def change do
    rename table(:case_investigations), :isolation_order_clearance_sent_date,
      to: :isolation_clearance_order_sent_date
  end
end
