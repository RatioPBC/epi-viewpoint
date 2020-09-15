defmodule Epicenter.Extra.Date do
  def days_ago(date_or_days, opts \\ [])

  def days_ago(nil, _opts) do
    nil
  end

  def days_ago(days, opts) when is_integer(days) do
    from = Keyword.get(opts, :from, Date.utc_today())
    Date.add(from, days * -1)
  end

  def days_ago(%Date{} = date, opts) do
    from = Keyword.get(opts, :from, Date.utc_today())
    Date.diff(from, date)
  end

  def render(%Date{} = date), do: "#{padded_number(date.month)}/#{padded_number(date.day)}/#{date.year}"
  def render(nil), do: ""

  defp padded_number(number) do
    String.pad_leading(to_string(number), 2, "0")
  end
end
