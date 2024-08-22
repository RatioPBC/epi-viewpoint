defmodule EpiViewpoint.Repo.Migrations.ConvertEmailsStringsToText do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      modify :address, :text, from: :string
      modify :source, :text, from: :string
      modify :tid, :text, from: :string
    end
  end
end
