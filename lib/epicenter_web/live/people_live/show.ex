defmodule EpicenterWeb.PeopleLive.Show do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases

  def mount(%{"id" => id}, _session, socket) do
    person = Cases.get_person(id) |> Cases.preload_lab_results()
    {:ok, assign(socket, person: person)}
  end
end
