defmodule Epicenter.Repo.Migrations.CreateLabResults do
  use Ecto.Migration

  def change do
    create table(:lab_results) do
      add :request_accession_number, :string

      timestamps()
    end
  end
end
