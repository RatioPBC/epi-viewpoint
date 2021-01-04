defmodule Epicenter.Repo.Migrations.CreateLogins do
  use Ecto.Migration

  def change() do
    create table(:logins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :seq, :bigserial
      add :session_id, :binary_id, null: false
      add :tid, :text
      add :user_agent, :text
      add :user_id, :binary_id, null: false

      timestamps()
    end
  end
end
