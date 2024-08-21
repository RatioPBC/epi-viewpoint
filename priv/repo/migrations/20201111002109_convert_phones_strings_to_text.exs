defmodule EpiViewpoint.Repo.Migrations.ConvertPhonesStringsToText do
  use Ecto.Migration

  def change do
    alter table(:phones) do
      modify :number, :text, from: :string
      modify :tid, :text, from: :string
      modify :source, :text, from: :string
      modify :type, :text, from: :string
    end
  end
end
