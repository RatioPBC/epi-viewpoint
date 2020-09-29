defmodule Epicenter.AuditLog do
  alias Epicenter.AuditLog.Revision

  def create_revision(changeset, author_id, action, event) do
    %{data: %struct_module{} = data, changes: changes} = changeset
    attrs = %{
      "changed_type" => "#{struct_module}",
      "changed_id" => data.id,
      "before_change" => data,
      "change" => changes
    }
    %Revision{} |> Revision.changeset(attrs) |> Epicenter.Repo.insert!


  end

  # TODO Versioned repo updates here...

  # take a repo function handle to execute
  # execute it

end