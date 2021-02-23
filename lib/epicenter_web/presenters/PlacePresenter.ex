defmodule EpicenterWeb.Presenters.PlacePresenter do
  alias Epicenter.Cases.Visit
  alias EpicenterWeb.Format

  def address(%Visit{} = visit) do
    Format.address(hd(visit.place.place_addresses))
  end
end
