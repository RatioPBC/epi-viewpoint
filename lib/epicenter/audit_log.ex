defmodule Epicenter.AuditLog do
  defmodule Meta do
    defstruct ~w{author_id reason_action reason_event}a
  end

  require Logger

  alias Epicenter.Accounts.User
  alias Epicenter.AuditLog.Meta
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases.Person
  alias Epicenter.Repo

  def insert(changeset, %Meta{} = meta, ecto_options \\ [], changeset_flattening_function \\ &recursively_get_changes_from_changeset/1) do
    create_revision(changeset, %Meta{} = meta, &Repo.insert/2, ecto_options, changeset_flattening_function)
  end

  def insert!(changeset, %Meta{} = meta, ecto_options \\ [], changeset_flattening_function \\ &recursively_get_changes_from_changeset/1) do
    create_revision(changeset, %Meta{} = meta, &Repo.insert!/2, ecto_options, changeset_flattening_function)
  end

  def update(changeset, %Meta{} = meta, ecto_options \\ [], changeset_flattening_function \\ &recursively_get_changes_from_changeset/1) do
    create_revision(changeset, %Meta{} = meta, &Repo.update/2, ecto_options, changeset_flattening_function)
  end

  def update!(changeset, %Meta{} = meta, ecto_options \\ [], changeset_flattening_function \\ &recursively_get_changes_from_changeset/1) do
    create_revision(changeset, %Meta{} = meta, &Repo.update!/2, ecto_options, changeset_flattening_function)
  end

  defp recursively_get_changes_from_changeset(%Ecto.Changeset{changes: changes, data: %{__struct__: type} = data}),
    do: changes |> recursively_get_changes_from_changeset() |> redact(type) |> add_primary_keys(data)

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

  def create_revision(
        %Ecto.Changeset{} = changeset,
        %Meta{} = meta,
        repo_fn,
        ecto_options \\ [],
        changeset_flattening_function
      )
      when is_function(repo_fn) do
    %{data: data} = changeset

    all_transaction_results =
      Ecto.Multi.new()
      |> Ecto.Multi.run(
        :non_audit_changeset,
        fn _repo, _changes ->
          case repo_fn.(changeset, ecto_options) do
            {:error, change} -> {:error, change}
            result -> {:ok, result}
          end
        end
      )
      |> Ecto.Multi.run(
        :audit_changeset,
        fn repo, %{non_audit_changeset: created_row} ->
          after_change =
            case created_row do
              {:ok, change} -> change
              change -> change
            end

          attrs = %{
            "after_change" => after_change,
            "application_version_sha" => application_version_sha(),
            "author_id" => meta.author_id,
            "before_change" => data,
            "change" => changeset_flattening_function.(changeset),
            "changed_id" => after_change.id,
            "changed_type" => module_name(data),
            "reason_action" => meta.reason_action,
            "reason_event" => meta.reason_event
          }

          %Revision{} |> Revision.changeset(attrs) |> repo.insert()
        end
      )
      |> Repo.transaction()

    case all_transaction_results do
      {:ok, %{non_audit_changeset: non_audit_changeset_result}} -> non_audit_changeset_result
      {:error, :non_audit_changeset, error, _} -> {:error, error}
      {:error, :audit_changeset, error, _} -> throw(error)
    end
  end

  defp redact(map, type) do
    Enum.reduce(
      type.__schema__(:redact_fields),
      map,
      fn key, acc ->
        acc
        |> Map.get_and_update(
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

  defp add_primary_keys(map, %{__struct__: type} = data) do
    Enum.reduce(
      type.__schema__(:primary_key),
      map,
      fn primary_key_component, acc ->
        Map.put(acc, primary_key_component, Map.get(data, primary_key_component))
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

  def view(_user, nil), do: nil

  def view(user, items) when is_list(items) do
    Enum.each(items, &view(user, &1))
  end

  def view(_user, %Person{id: nil}), do: nil

  def view(%User{id: user_id}, %Person{id: subject_id}) do
    subject_type = "Person"

    Logger.info("User(#{user_id}) viewed #{subject_type}(#{subject_id})",
      audit_log: true,
      audit_user_id: user_id,
      audit_action: "view",
      audit_subject_id: subject_id,
      audit_subject_type: subject_type
    )
  end

  defp application_version_sha do
    Application.get_env(:epicenter, :application_version_sha)
  end
end
