defmodule Epicenter.Repo.Migrations.AddMfaSecretToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :mfa_secret, :text
    end
  end
end
