defmodule Epicenter.Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres, otp_app: :epicenter

  defmodule Versioned do
    def all_versions(record), do: PaperTrail.get_versions(record) |> Enum.sort_by(& &1.id, :desc)
    def last_version(record), do: PaperTrail.get_version(record)

    def insert(changeset), do: changeset |> PaperTrail.insert() |> unwrap_result()
    def insert!(changeset), do: changeset |> PaperTrail.insert!()
    def update(changeset), do: changeset |> update_if_changes(&PaperTrail.update/1) |> unwrap_result()
    def update!(changeset), do: changeset |> update_if_changes(&PaperTrail.update!/1)

    # # #

    defp update_if_changes(changeset, update_fn) do
      case changeset do
        %{valid?: true, changes: changes} when changes == %{} -> changeset.data
        changeset -> changeset |> update_fn.()
      end
    end

    defp unwrap_result({:ok, result}), do: {:ok, result |> Map.get(:model)}
    defp unwrap_result({:error, changeset}), do: {:error, changeset}
  end
end
