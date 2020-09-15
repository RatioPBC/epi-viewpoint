defmodule EpicenterWeb.PeopleLive.Show do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [carat_right_icon: 2]

  alias Epicenter.Cases
  alias Epicenter.Cases.Person
  alias Epicenter.Extra

  def mount(%{"id" => id}, _session, socket) do
    person = Cases.get_person(id) |> Cases.preload_lab_results() |> Cases.preload_addresses()
    socket = socket
    |> assign(person: person)
    |> assign(addresses: person.addresses)

    {:ok, socket}
  end

  def age(%Person{dob: dob}) do
    Date.diff(Date.utc_today(), dob) |> Integer.floor_div(365)
  end

  def full_name(person),
    do: [person.first_name, person.last_name] |> Euclid.Exists.filter() |> Enum.join(" ")

  def email_addresses(person) do
    person
    |> Cases.preload_emails()
    |> Map.get(:emails)
    |> Enum.map(& &1.address)
  end

  def phone_numbers(person) do
    person
    |> Cases.preload_phones()
    |> Map.get(:phones)
    |> Enum.map(fn %{number: digits} ->
      digits |> Integer.digits() |> Enum.map(&to_string/1) |> List.insert_at(-5, "-") |> List.insert_at(-9, "-") |> Enum.join()
    end)
  end

  def string_or_unknown(value) do
    if Euclid.Exists.present?(value),
      do: value,
      else: unknown_value()
  end

  def list_or_unknown(values) do
    if Euclid.Exists.present?(values) do
      Phoenix.HTML.Tag.content_tag :ul do
        Enum.map(values, &Phoenix.HTML.Tag.content_tag(:li, &1))
      end
    else
      unknown_value()
    end
  end

  def unknown_value do
    Phoenix.HTML.Tag.content_tag(:span, "Unknown", class: "unknown")
  end
end
