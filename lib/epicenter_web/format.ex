defmodule EpicenterWeb.Format do
  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Phone
  alias Epicenter.Extra
  alias EpicenterWeb.PresentationConstants
  alias Epicenter.DateParser

  def address(nil), do: ""

  def address(%{street: street, city: city, state: state, postal_code: postal_code}) do
    non_postal_code = [street, city, state] |> Euclid.Extra.List.compact() |> Enum.join(", ")
    [non_postal_code, postal_code] |> Euclid.Extra.List.compact() |> Enum.join(" ")
  end

  def address(addresses) when is_list(addresses), do: addresses |> Enum.map(&address/1) |> Enum.join("; ")

  def date(nil, default), do: default
  def date(dates, :sorted) when is_list(dates), do: dates |> Enum.map(&to_date/1) |> Enum.sort(Date) |> date()

  def date(value, _default), do: date(value)

  def date(nil), do: ""
  def date(%Date{} = date), do: "#{zero_pad(date.month, 2)}/#{zero_pad(date.day, 2)}/#{date.year}"

  def date(%DateTime{} = datetime), do: datetime |> to_date() |> date()
  def date(dates) when is_list(dates), do: dates |> Enum.map(&date/1) |> Enum.join(", ")

  def date_time_with_zone(nil), do: ""
  def date_time_with_zone(%DateTime{} = date_time), do: Calendar.strftime(date_time, "%m/%d/%Y at %I:%M%P %Z")

  def date_time_with_presented_time_zone(nil), do: ""

  def date_time_with_presented_time_zone(%DateTime{} = date_time),
    do: date_time |> DateTime.shift_zone!(PresentationConstants.presented_time_zone()) |> date_time_with_zone()

  def demographic(%{"major" => major, "detailed" => detailed}, field), do: demographic(%{major: major, detailed: detailed}, field)
  def demographic(%{major: major, detailed: detailed}, field), do: demographic(Extra.List.sorted_flat_compact([major, detailed]), field)
  def demographic(map, field) when is_map(map), do: map |> Extra.Map.to_list(:depth_first) |> demographic(field)
  def demographic(values, field) when is_list(values), do: values |> Enum.map(&demographic(&1, field)) |> Enum.sort()
  def demographic(nil, _field), do: nil
  def demographic("unknown", _field), do: "Unknown"
  def demographic("declined_to_answer", _field), do: "Declined to answer"
  def demographic(value, :external_id), do: "ID: #{value}"
  def demographic(value, field), do: Demographic.find_humanized_value(field, value)

  def person(nil), do: ""
  def person(%Epicenter.Cases.Person{} = person), do: person(Epicenter.Cases.Person.coalesce_demographics(person))
  def person(%{first_name: first_name, last_name: last_name}), do: [first_name, last_name] |> Euclid.Exists.join(" ")

  def phone(nil), do: ""
  def phone(%Phone{number: number}), do: phone(number)
  def phone(string) when is_binary(string), do: reformat_phone(string)
  def phone(phone_numbers) when is_list(phone_numbers), do: phone_numbers |> Enum.map(&phone/1) |> Enum.join(", ")

  def time(nil), do: ""
  def time(%Time{} = time), do: "#{zero_pad(to_twelve_hour(time.hour), 2)}:#{zero_pad(time.minute, 2)}"

  # # #

  defp to_date(%DateTime{} = date_time) do
    date_time |> DateTime.shift_zone!(EpicenterWeb.PresentationConstants.presented_time_zone()) |> DateTime.to_date()
  end

  defp to_date(date) when is_binary(date), do: DateParser.parse_mm_dd_yyyy!(date)
  defp to_date(date), do: date

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
