defmodule Epicenter.AuditLog do
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Repo

  def insert(changeset, author_id, action, event) do
    create_revision(changeset, author_id, action, event, &Repo.insert/1)
  end

  def insert!(changeset, author_id, action, event) do
    create_revision(changeset, author_id, action, event, &Repo.insert!/1)
  end

  def update(changeset, author_id, action, event) do
    create_revision(changeset, author_id, action, event, &Repo.update/1)
  end

  def update!(changeset, author_id, action, event) do
    create_revision(changeset, author_id, action, event, &Repo.update!/1)
  end

  def create_revision(changeset, author_id, action, event, repo_fn) when is_function(repo_fn) do
    %{data: data, changes: changes} = changeset

    result = repo_fn.(changeset)

    after_change =
      case result do
        {:ok, change} -> change
        change -> change
      end

    attrs = %{
      "after_change" => after_change,
      "author_id" => author_id,
      "before_change" => data,
      "change" => changes,
      "changed_id" => after_change.id,
      "changed_type" => module_name(data),
      "reason_action" => action,
      "reason_event" => event
    }

    {:ok, _revision} = %Revision{} |> Revision.changeset(attrs) |> Repo.insert()
    result
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
end
