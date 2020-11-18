defmodule Epicenter.Repo.Migrations.MakeUsersDisabledFieldNotNull do
  use Ecto.Migration

  def change do
    execute("update users set disabled=false where disabled is null;", "")

    alter table(:users) do
      modify :disabled, :boolean, default: false, null: false, from: :boolean
    end
  end
end
