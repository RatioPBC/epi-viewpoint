defmodule Epicenter.Repo.Migrations.AddExpiresAtToUsersTokens do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      add :expires_at, :naive_datetime
    end
  end
end
