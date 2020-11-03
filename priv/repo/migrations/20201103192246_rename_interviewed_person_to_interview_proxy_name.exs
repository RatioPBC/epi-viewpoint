defmodule Epicenter.Repo.Migrations.AddInterviewWithProxyAndRenameInterviewedPerson do
  use Ecto.Migration

  def change do
    rename table(:case_investigations), :person_interviewed, to: :interview_proxy_name
  end
end
