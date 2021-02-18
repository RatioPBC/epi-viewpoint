defmodule Epicenter.Repo.Migrations.AddContactPhoneAndEmailToPlaces do
  use Ecto.Migration

  def change do
    alter table(:places) do
      add :contact_name, :text
      add :contact_phone, :text
      add :contact_email, :text
    end
  end
end
