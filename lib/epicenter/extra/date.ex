defmodule Epicenter.Extra.Date do
  defmodule NilFirst do
    def compare(nil, nil), do: :eq
    def compare(nil, _date2), do: :gt
    def compare(_date1, nil), do: :lt
    def compare(date1, date2), do: Date.compare(date1, date2)
  end

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
