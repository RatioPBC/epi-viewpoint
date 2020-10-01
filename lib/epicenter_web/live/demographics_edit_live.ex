defmodule EpicenterWeb.DemographicsEditLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias EpicenterWeb.Session

  def mount(%{"id" => id}, _session, socket) do
    person = %{Cases.get_person(id) | originator: Session.get_current_user()}
    changeset = person |> Cases.change_person(%{})

    {
      :ok,
      assign(
        socket,
        changeset: changeset,
        person: person
      )
    }
  end

end
