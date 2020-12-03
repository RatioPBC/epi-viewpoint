defmodule EpicenterWeb.Presenters.LabResultPresenter do
  import EpicenterWeb.Unknown, only: [string_or_unknown: 1]

  def pretty_result(nil), do: string_or_unknown(nil)
  def pretty_result(result), do: string_or_unknown(result) |> String.capitalize()
end
