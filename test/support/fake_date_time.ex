defmodule FakeDateTime do
  @fake_date_time ~U[2020-10-31 10:30:00Z]
  def utc_now(), do: @fake_date_time
end
