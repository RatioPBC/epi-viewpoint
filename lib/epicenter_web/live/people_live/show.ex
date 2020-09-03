defmodule EpicenterWeb.PeopleLive.Show do
  use EpicenterWeb, :live_view

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

  def phone_number(person) do
    person
    |> Cases.preload_phones()
    |> Map.get(:phones)
    |> Enum.map(fn %{number: digits} ->
      digits |> Integer.digits() |> Enum.map(&to_string/1) |> List.insert_at(-5, "-") |> List.insert_at(-9, "-") |> Enum.join()
    end)
    |> Enum.join(", ")
  end

  # # # icons

  def carat_right_icon(width, height) do
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 8 12" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M2.00009 0L0.590088 1.41L5.17009 6L0.590088 10.59L2.00009 12L8.00009 6L2.00009 0Z" fill="#B0B0B0"/>
    </svg>
    """
    |> raw()
  end

  def phone_icon(width, height) do
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M3.62 7.79C5.06 10.62 7.38 12.93 10.21 14.38L12.41 12.18C12.68 11.91 13.08 11.82 13.43 11.94C14.55 12.31 15.76 12.51 17 12.51C17.55 12.51 18 12.96 18 13.51V17C18 17.55 17.55 18 17 18C7.61 18 0 10.39 0 1C0 0.45 0.45 0 1 0H4.5C5.05 0 5.5 0.45 5.5 1C5.5 2.25 5.7 3.45 6.07 4.57C6.18 4.92 6.1 5.31 5.82 5.59L3.62 7.79Z" fill="white"/>
    </svg>
    """
    |> raw()
  end
end
