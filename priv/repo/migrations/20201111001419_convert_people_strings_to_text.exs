defmodule EpiViewpoint.Repo.Migrations.ConvertPeopleStringsToText do
  use Ecto.Migration

  def change do
    alter table(:people) do
      modify :tid, :text, from: :string
    end
  end
end
