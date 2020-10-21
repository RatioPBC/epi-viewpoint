defmodule EpicenterWeb.PersonHelpers do
  alias Epicenter.Cases.Person

  def demographic_field(person, field) do
    Person.coalesce_demographics(person) |> Map.get(field)
  end
end
