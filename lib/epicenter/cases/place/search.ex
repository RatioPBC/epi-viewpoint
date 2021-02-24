defmodule Epicenter.Cases.Place.Search do
  import Ecto.Query

  alias Epicenter.Cases.Place
  alias Epicenter.Cases.PlaceAddress
  alias Epicenter.Repo

  def find(search_string) do
    string = "#{search_string}%"

    query =
      from address in PlaceAddress,
        join: place in Place,
        on: place.id == address.place_id,
        where: ilike(place.name, ^string) or ilike(address.street, ^string),
        preload: [place: place]

    Repo.all(query)
  end
end
