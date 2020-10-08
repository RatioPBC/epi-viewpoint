defmodule Epicenter.AuditLog do
  defmodule Meta do
    defstruct ~w{author_id reason_action reason_event}a
  end

  alias Epicenter.AuditLog.Meta
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Repo

  def insert(changeset, %Meta{} = meta, ecto_options \\ []) do
    create_revision(changeset, %Meta{} = meta, &Repo.insert/2, ecto_options)
  end

  def insert!(changeset, %Meta{} = meta, ecto_options \\ []) do
    create_revision(changeset, %Meta{} = meta, &Repo.insert!/2, ecto_options)
  end

  def update(changeset, %Meta{} = meta, ecto_options \\ []) do
    create_revision(changeset, %Meta{} = meta, &Repo.update/2, ecto_options)
  end

  def update!(changeset, %Meta{} = meta, ecto_options \\ []) do
    create_revision(changeset, %Meta{} = meta, &Repo.update!/2, ecto_options)
  end

  defp recursively_get_changes_from_changeset(%Ecto.Changeset{changes: changes}),
    do: recursively_get_changes_from_changeset(changes)

  defp recursively_get_changes_from_changeset(%_struct{} = data),
    do: data

  defp recursively_get_changes_from_changeset(data) when is_map(data),
    do:
      data
      |> Enum.map(fn {k, v} -> {k, recursively_get_changes_from_changeset(v)} end)
      |> Map.new()

  defp recursively_get_changes_from_changeset(data) when is_list(data),
    do: data |> Enum.map(fn v -> recursively_get_changes_from_changeset(v) end)

  defp recursively_get_changes_from_changeset(data),
    do: data

  def create_revision(changeset, %Meta{} = meta, repo_fn, ecto_options \\ []) when is_function(repo_fn) do
    %{data: data} = changeset

    result = repo_fn.(changeset, ecto_options)

    after_change =
      case result do
        {:ok, change} -> change
        {:error, _change} -> nil
        change -> change
      end

    if after_change != nil do
      attrs = %{
        "after_change" => after_change |> redact(),
        "author_id" => meta.author_id,
        "before_change" => data |> redact(),
        "change" => recursively_get_changes_from_changeset(changeset) |> redact(),
        "changed_id" => after_change.id,
        "changed_type" => module_name(data),
        "reason_action" => meta.reason_action,
        "reason_event" => meta.reason_event
      }

      {:ok, _revision} = %Revision{} |> Revision.changeset(attrs) |> Repo.insert()
    end

    result
  end

  @redacted_fields ["password", :password]
  defp redact(changes) do
    Enum.reduce(
      @redacted_fields,
      changes,
      fn key, acc ->
        Map.get_and_update(
          acc,
          key,
          fn
            nil -> :pop
            val -> {val, "<<REDACTED>>"}
          end
        )
        |> elem(1)
      end
    )
  end

  def get_revision(id), do: Revision |> Repo.get(id)

  def module_name(%module{} = _struct) do
    module |> module_name()
  end

  def module_name(module) do
    module |> inspect() |> String.split(".") |> Enum.reject(&(&1 in ~w{Epicenter EpicenterWeb})) |> Enum.join(".")
  end

  def revisions(changed_type) do
    Revision.Query.with_changed_type(changed_type) |> Repo.all()
  end

  def entries_for(model_id) do
    Revision.Query.with_changed_id(model_id) |> Repo.all()
  end
end
