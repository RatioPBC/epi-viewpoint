defmodule Epicenter.Cases.Case do
  defstruct ~w{dob first_name last_name latest_result latest_sample_date tid}a

  alias Epicenter.Cases.Case
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person

  def new(people) when is_list(people) do
    people |> Enum.map(&new/1)
  end

  def new(person) do
    {latest_result, latest_sample_date} =
      case Person.latest_lab_result(person) do
        nil -> {nil, nil}
        %LabResult{} = lab_result -> {lab_result.result, lab_result.sample_date}
      end

    %Case{
      dob: person.dob,
      first_name: person.first_name,
      last_name: person.last_name,
      latest_result: latest_result,
      latest_sample_date: latest_sample_date,
      tid: person.tid
    }
  end
end
