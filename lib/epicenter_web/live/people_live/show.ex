defmodule EpicenterWeb.PeopleLive.Show do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias Epicenter.Cases.Person

  def mount(%{"id" => id}, _session, socket) do
    person = Cases.get_person(id) |> Cases.preload_lab_results()
    {:ok, assign(socket, person: person)}
  end

  def age(%Person{dob: dob}) do
    Date.diff(Date.utc_today(), dob) |> Integer.floor_div(365)
  end
end
