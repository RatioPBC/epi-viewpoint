defmodule EpiViewpoint.Repo.Migrations.AddIsPreferredToEmails do
  use Ecto.Migration

  def change() do
    alter table(:emails) do
      add :is_preferred, :boolean
    end
  end
end
