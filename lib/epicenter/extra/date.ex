defmodule Epicenter.Extra.Date do
  def days_ago(days, opts \\ []) do
    from = Keyword.get(opts, :from, Date.utc_today())
    Date.add(from, days * -1)
  end
end
