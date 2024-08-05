defmodule EpicenterWeb.Views.DateExtraction do
  import Ecto.Changeset

  alias EpicenterWeb.PresentationConstants

  def extract_and_validate_date(changeset, date_key, time_key, am_pm_key) do
    with {_, date} <- fetch_field(changeset, date_key),
         {_, time} <- fetch_field(changeset, time_key),
         {_, am_pm} <- fetch_field(changeset, am_pm_key),
         {^date_key, {:ok, _}} <- {date_key, convert_time(date, "12:00", "PM")},
         {^time_key, {:ok, _}} <- {time_key, convert_time("01/01/2000", time, "PM")},
         {:together, {:ok, _}} <- {:together, convert_time(date, time, am_pm)} do
      changeset
    else
      {:together, _} -> changeset |> add_error(time_key, "is invalid")
      {field, _} -> changeset |> add_error(field, "is invalid")
      _ -> changeset
    end
  end

  def convert_time(datestring, timestring, ampmstring) do
    with {:ok, datetime} <-
           Timex.parse(
             "#{datestring} #{timestring} #{ampmstring}",
             "{0M}/{0D}/{YYYY} {h12}:{m} {AM}"
           ),
         %Timex.TimezoneInfo{} = timezone <-
           Timex.timezone(PresentationConstants.presented_time_zone(), datetime),
         %DateTime{} = time <- Timex.to_datetime(datetime, timezone) do
      {:ok, time}
    end
  end
end
