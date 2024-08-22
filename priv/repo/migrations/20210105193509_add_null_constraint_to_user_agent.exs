defmodule EpiViewpoint.Repo.Migrations.AddNullConstraintToUserAgent do
  use Ecto.Migration

  def up do
    alter table(:logins) do
      modify :user_agent, :text, null: false
    end
  end

  def down do
    alter table(:logins) do
      modify :user_agent, :text, null: true
    end
  end
end
