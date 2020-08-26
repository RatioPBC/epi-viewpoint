defmodule Epicenter.Repo do
  use Ecto.Repo,
    otp_app: :epicenter,
    adapter: Ecto.Adapters.Postgres

  defmodule Versioned do
    def all_versions(record), do: PaperTrail.get_versions(record) |> Enum.sort_by(& &1.id, :desc)
    def last_version(record), do: PaperTrail.get_version(record)

    def insert(changeset), do: changeset |> PaperTrail.insert() |> unwrap_result()
    def insert!(changeset), do: changeset |> PaperTrail.insert!()
    def update(changeset), do: changeset |> PaperTrail.update() |> unwrap_result()

    # # #

    defp unwrap_result({:ok, result}), do: {:ok, result |> Map.get(:model)}
    defp unwrap_result({:error, changeset}), do: {:error, changeset}
  end
end
