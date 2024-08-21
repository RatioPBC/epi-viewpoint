defmodule EpiViewpoint.Repo.Migrations.RenameUsernameToNameAndRemoveUniqueness do
  use Ecto.Migration

  def change do
    drop_if_exists index(:users, [:username])
    rename table(:users), :username, to: :name
  end
end
