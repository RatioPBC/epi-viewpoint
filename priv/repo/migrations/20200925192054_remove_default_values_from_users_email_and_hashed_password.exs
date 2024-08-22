defmodule EpiViewpoint.Repo.Migrations.RemoveDefaultValuesFromUsersEmailAndHashedPassword do
  use Ecto.Migration

  # the previous migration assigned random values for email and hashed password so existing users had a value,
  # and this migration stops new rows from getting random values

  def change do
    alter table(:users) do
      modify :email, :citext, null: false, default: nil
      modify :hashed_password, :string, null: false, default: nil
    end
  end
end
