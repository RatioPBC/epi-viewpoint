defmodule Epicenter.Repo.Migrations.AddDiscontinuedAtAndDiscontinueReasonToCaseInvestigation do
  use Ecto.Migration

  def change do
    alter table(:case_investigations) do
      add :discontinued_at, :utc_datetime
      add :discontinue_reason, :string
    end
  end
end
