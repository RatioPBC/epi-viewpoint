defmodule EpicenterWeb.Presenters.PlacePresenter do
  alias Epicenter.Cases.Place
  alias EpicenterWeb.Format

  def address(%Place{place_addresses: []}), do: ""
  def address(%Place{place_addresses: [address | _]}), do: Format.address(address)
end
