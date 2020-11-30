defmodule EpicenterWeb.PersonHelpers do
  alias Epicenter.Cases.Person
  alias Epicenter.MajorDetailed
  alias EpicenterWeb.Format

  def demographic_field(person, field),
    do: person |> Person.coalesce_demographics() |> Map.get(field)

  def demographic_field(person, :race = field, :format),
    do: person |> demographic_field(field) |> MajorDetailed.for_display() |> Format.demographic(field)

  def demographic_field(person, field, :format),
    do: person |> demographic_field(field) |> Format.demographic(field)
end
