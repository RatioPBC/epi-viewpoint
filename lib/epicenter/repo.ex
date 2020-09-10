defmodule Epicenter.Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres, otp_app: :epicenter

  defmodule Versioned do
    def all_versions(record),
      do: PaperTrail.get_versions(record) |> Enum.sort_by(& &1.id, :desc)

    def last_version(record),
      do: PaperTrail.get_version(record)

    def insert(changeset, options \\ []),
      do: changeset |> PaperTrail.insert(originator: get_originator!(changeset), ecto_options: options[:ecto_options]) |> unwrap_result()

    def insert!(changeset, options \\ []),
      do: changeset |> PaperTrail.insert!(originator: get_originator!(changeset), ecto_options: options[:ecto_options])

    def originated_by(data, originator), do: data |> Ecto.Changeset.change(originator: originator)

    def update(changeset),
      do: changeset |> update_if_changes(&PaperTrail.update(&1, originator: get_originator!(changeset))) |> unwrap_result()

    def update!(changeset),
      do: changeset |> update_if_changes(&PaperTrail.update!(&1, originator: get_originator!(changeset)))

    def get_originator!(changeset),
      do: Ecto.Changeset.get_field(changeset, :originator) || raise("originator not in changeset!")

    # # #

    defp update_if_changes(changeset, update_fn) do
      case changeset do
        %{valid?: true, changes: changes} when changes == %{} -> changeset.data
        changeset -> changeset |> update_fn.()
      end
    end

    defp unwrap_result({:ok, result}),
      do: {:ok, result |> Map.get(:model)}

    defp unwrap_result({:error, changeset}),
      do: {:error, changeset}
  end
end
