defmodule Epicenter.Cases do
  alias Epicenter.Cases.LabResult
  alias Epicenter.Repo

  def change_lab_result(%LabResult{} = lab_result, attrs), do: LabResult.changeset(lab_result, attrs)
  def create_lab_result!(attrs), do: %LabResult{} |> change_lab_result(attrs) |> Repo.insert!()
  def list_lab_results(), do: LabResult.Query.all() |> Repo.all()
end
