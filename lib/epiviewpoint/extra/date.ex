defmodule EpiViewpoint.Extra.Date do
  alias EpiViewpoint.Extra

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

  def years_ago(date_or_days, opts \\ [])

  def years_ago(nil, _opts),
    do: nil

  def years_ago(years, opts) when is_integer(years) do
    from = opts |> Keyword.get(:from, Date.utc_today())
    from |> Map.put(:year, from.year - years)
  end

  def years_ago(%Date{} = date, opts),
    do: opts |> Keyword.get(:from, Date.utc_today()) |> Timex.diff(date, :year)
end
