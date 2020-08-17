defmodule Epicenter.Cases.Case do
  defstruct ~w{dob first_name last_name latest_result latest_sample_date}a

  alias Epicenter.Cases.Case
  alias Epicenter.Cases.Person

  def new(people) when is_list(people) do
    people |> Enum.map(&new/1)
  end

  def new(person) do
    latest_lab_result = Person.latest_lab_result(person)

    %Case{
      dob: person.dob,
      first_name: person.first_name,
      last_name: person.last_name,
      latest_result: latest_lab_result.result,
      latest_sample_date: latest_lab_result.sample_date
    }
  end
end
