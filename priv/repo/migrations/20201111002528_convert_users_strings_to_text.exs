defmodule Epicenter.Repo.Migrations.ConvertUsersStringsToText do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :hashed_password, :text, from: :string
      modify :name, :text, from: :string
      modify :tid, :text, from: :string
    end
  end
end
