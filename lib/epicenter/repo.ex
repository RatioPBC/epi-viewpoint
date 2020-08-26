defmodule Epicenter.Repo do
  use Ecto.Repo,
    otp_app: :epicenter,
    adapter: Ecto.Adapters.Postgres

  alias Epicenter.Version

  def insert_with_version(changeset), do: changeset |> Version.insert()
  def insert_with_version!(changeset), do: changeset |> Version.insert!()
  def update_with_version(changeset), do: changeset |> Version.update()
end
