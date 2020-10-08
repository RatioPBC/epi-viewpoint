defmodule Epicenter.Repo.Migrations.UpdatePhoneNumberToString do
  use Ecto.Migration

  def change do
    alter table(:phones) do
      modify :number, :string, from: :integer
    end
  end
end
