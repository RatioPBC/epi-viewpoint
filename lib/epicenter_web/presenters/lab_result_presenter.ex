defmodule EpicenterWeb.Presenters.LabResultPresenter do
  import EpicenterWeb.Unknown, only: [string_or_unknown: 1]

  alias Epicenter.Cases.LabResult
  alias Epicenter.Extra

  def pretty_result(nil), do: string_or_unknown(nil)
  def pretty_result(result), do: string_or_unknown(result) |> String.capitalize()

  def latest_positive(lab_results) do
    lab_result = LabResult.latest(lab_results, :positive)

    if lab_result do
      "#{pretty_result(lab_result.result)}, #{days_ago(lab_result)}"
    else
      ""
    end
  end

  defp days_ago(%{sampled_on: nil} = _lab_result), do: "unknown date"
  defp days_ago(%{sampled_on: sampled_on} = _lab_result), do: sampled_on |> Extra.Date.days_ago_string()
end
