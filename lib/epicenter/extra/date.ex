defmodule Epicenter.Extra.Date do
  alias Epicenter.Extra

  defmodule NilFirst do
    def compare(nil, nil), do: :eq
    def compare(nil, _date2), do: :gt
    def compare(_date1, nil), do: :lt
    def compare(date1, date2), do: Date.compare(date1, date2)
  end

  def days_ago(date_or_days, opts \\ [])

  def days_ago(nil, _opts),
    do: nil

  def days_ago(days, opts) when is_integer(days),
    do: opts |> Keyword.get(:from, Date.utc_today()) |> Date.add(days * -1)

  def days_ago(%Date{} = date, opts),
    do: opts |> Keyword.get(:from, Date.utc_today()) |> Date.diff(date)

  def days_ago_string(%Date{} = date, opts \\ []),
    do: days_ago(date, opts) |> Extra.String.pluralize("day ago", "days ago")

  def render(%Date{} = date),
    do: "#{padded_number(date.month)}/#{padded_number(date.day)}/#{date.year}"

  def render(nil),
    do: ""

  defp padded_number(number),
    do: String.pad_leading(to_string(number), 2, "0")
end
