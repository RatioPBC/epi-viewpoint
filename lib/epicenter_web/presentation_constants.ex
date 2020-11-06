defmodule EpicenterWeb.PresentationConstants do
  @presented_time_zone "America/New_York"
  @am_pm_options ~w{AM PM}

  def am_pm_options(), do: @am_pm_options
  def presented_time_zone(), do: @presented_time_zone
end
