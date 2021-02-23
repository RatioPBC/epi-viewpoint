defmodule EpicenterWeb.Presenters.GeographyPresenter do
  def states(nil) do
    ~w{AL AK AS AZ AR CA CO CT DE DC FL GA GO HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MP MT NE NV NH NJ NM NY NC ND OH OK OR PA PR RI SC SD TN TX UT VT VA VI WA WV WI WY}
    |> Enum.map(&{&1, &1})
    |> (&[{"", nil} | &1]).()
  end

  def states(current) do
    [{current, current} | states(nil)]
    |> Enum.uniq()
    |> Enum.sort_by(&elem(&1, 0))
  end
end
