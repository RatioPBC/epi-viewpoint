defmodule EpicenterWeb.Presenters.LabResultPresenter do
  import EpicenterWeb.Unknown, only: [string_or_unknown: 1]

  alias Epicenter.Cases.LabResult
  alias EpicenterWeb.Format

  def latest_positive(lab_results),
    do: if(lab_result = LabResult.latest(lab_results, :positive), do: Format.date(lab_result.sampled_on, "Unknown date"), else: "")

  def pretty_result(nil), do: string_or_unknown(nil)
  def pretty_result(result), do: string_or_unknown(result) |> String.capitalize()
end
