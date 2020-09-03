defmodule Epicenter.Repo.Migrations.RemoveNullConstraintFromPhoneType do
  use Ecto.Migration

  def down do
    alter table(:phones) do
      modify :type, :string, null: false
    end
  end

  def up do
    alter table(:phones) do
      modify :type, :string, null: true
    end
  end
end
