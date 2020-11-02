defmodule Epicenter.Format do
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.Phone
  alias Euclid.Extra

  def address(nil), do: ""

  def address(%Address{street: street, city: city, state: state, postal_code: postal_code}) do
    non_postal_code = [street, city, state] |> Extra.List.compact() |> Enum.join(", ")
    [non_postal_code, postal_code] |> Extra.List.compact() |> Enum.join(" ")
  end

  def employment(nil), do: nil
  def employment(employment), do: employment |> String.replace("_", " ") |> String.capitalize()

  def date(nil), do: ""
  def date(%Date{} = date), do: "#{zero_pad(date.month, 2)}/#{zero_pad(date.day, 2)}/#{date.year}"

  def date_time_with_zone(nil), do: ""

  def date_time_with_zone(%DateTime{} = date_time) do
    Calendar.strftime(date_time, "%m/%d/%Y at %I:%M%P %Z")
  end

  def marital_status(nil), do: nil
  def marital_status(marital_status), do: marital_status |> String.capitalize()

  def person(nil), do: ""
  def person(%Epicenter.Cases.Person{} = person), do: person(Epicenter.Cases.Person.coalesce_demographics(person))
  def person(%{first_name: first_name, last_name: last_name}), do: [first_name, last_name] |> Euclid.Exists.join(" ")

  def phone(nil), do: ""
  def phone(%Phone{number: number}), do: phone(number)
  def phone(string) when is_binary(string), do: reformat_phone(string)

  def time(nil), do: ""
  def time(%Time{} = time), do: "#{zero_pad(to_twelve_hour(time.hour), 2)}:#{zero_pad(time.minute, 2)}"

  # # #

  defp reformat_phone(string) when byte_size(string) == 10,
    do: string |> Number.Phone.number_to_phone(area_code: true)

  defp reformat_phone(string) when byte_size(string) == 11,
    do: string |> String.slice(1..-1) |> Number.Phone.number_to_phone(area_code: true, country_code: String.at(string, 0))

  defp reformat_phone(string),
    do: string

  defp to_twelve_hour(0),
    do: 12

  defp to_twelve_hour(hour) when hour > 12,
    do: to_twelve_hour(rem(hour, 12))

  defp to_twelve_hour(hour),
    do: hour

  defp zero_pad(value, zeros),
    do: String.pad_leading(to_string(value), zeros, "0")
end
