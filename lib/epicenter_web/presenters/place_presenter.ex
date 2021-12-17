defmodule EpicenterWeb.Presenters.PlacePresenter do
  alias Epicenter.Cases.Place
  alias EpicenterWeb.Format

  def address(%Place{} = place) do
    Format.address(hd(place.place_addresses))
  end

  def place_name(%Place{} = place) do
    place.name
  end
end
