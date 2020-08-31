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
end
