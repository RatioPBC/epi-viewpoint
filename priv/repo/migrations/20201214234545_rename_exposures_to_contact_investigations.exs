defmodule EpiViewpoint.Repo.Migrations.RenameExposuresToContactInvestigations do
  use Ecto.Migration

  def change do
    rename table(:exposures), to: table(:contact_investigations)
    rename table(:investigation_notes), :exposure_id, to: :contact_investigation_id
  end
end
