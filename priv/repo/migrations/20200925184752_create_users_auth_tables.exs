defmodule EpiViewpoint.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    alter table(:users) do
      add :email, :citext, null: false, default: fragment("md5(random()::text)")
      add :hashed_password, :string, null: false, default: fragment("md5(random()::text)")
      add :confirmed_at, :naive_datetime
    end

    create unique_index(:users, [:email])

    create table(:users_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
