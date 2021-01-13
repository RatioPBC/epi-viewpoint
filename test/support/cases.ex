defmodule Epicenter.Test.Cases do
  import Euclid.Test.Extra.Assertions

  alias Epicenter.Cases.Person
  alias Epicenter.Repo

  def assignee_tid(%Person{id: person_id}) do
    Repo.get(Person, person_id)
    |> Epicenter.Cases.preload_assigned_to()
    |> Map.get(:assigned_to)
    |> case do
      nil -> nil
      user -> user.tid
    end
  end

  def assert_assignees(%{} = expected) do
    Enum.map(expected, fn {person, _} -> {person, assignee_tid(person)} end)
    |> Enum.into(%{})
    |> assert_eq(expected)
  end
end
