defmodule Epicenter.Repo.Migrations.DropVersions do
  use Ecto.Migration

  def up do
    drop table("versions")
  end
end
