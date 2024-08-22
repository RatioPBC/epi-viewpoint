defmodule EpiViewpointWeb.Presenters.PlacePresenter do
  alias EpiViewpoint.Cases.Place
  alias EpiViewpointWeb.Format

  def address(%Place{place_addresses: []}), do: ""
  def address(%Place{place_addresses: [address | _]}), do: Format.address(address)
end
