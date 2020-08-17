defmodule Epicenter.Cases.Case do
  defstruct ~w{dob first_name last_name}a

  @person_fields ~w{dob first_name last_name}a

  alias Epicenter.Cases.Case

  def new(people) when is_list(people) do
    people |> Enum.map(&new/1)
  end

  def new(person) do
    person_data = person |> Map.take(@person_fields)
    %Case{} |> Map.merge(person_data)
  end
end
