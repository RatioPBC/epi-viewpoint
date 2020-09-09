defmodule EpicenterWeb.PeopleLive.Show do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [carat_right_icon: 2]

  alias Epicenter.Cases
  alias Epicenter.Cases.Person

  def mount(%{"id" => id}, _session, socket) do
    person = Cases.get_person(id) |> Cases.preload_lab_results()
    {:ok, assign(socket, person: person)}
  end

  def age(%Person{dob: dob}) do
    Date.diff(Date.utc_today(), dob) |> Integer.floor_div(365)
  end

  def full_name(person),
    do: [person.first_name, person.last_name] |> Euclid.Exists.filter() |> Enum.join(" ")

  def email_address(person) do
    person
    |> Cases.preload_emails()
    |> Map.get(:emails)
    |> Enum.map(& &1.address)
    |> Enum.join(", ")
  end

  def phone_number(person) do
    person
    |> Cases.preload_phones()
    |> Map.get(:phones)
    |> Enum.map(fn %{number: digits} ->
      digits |> Integer.digits() |> Enum.map(&to_string/1) |> List.insert_at(-5, "-") |> List.insert_at(-9, "-") |> Enum.join()
    end)
    |> Enum.join(", ")
  end
end
