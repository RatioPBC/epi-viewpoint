defmodule EpicenterWeb.DemographicsEditLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2]

  alias Epicenter.Cases

  def mount(%{"id" => id}, session, socket) do
    socket = socket |> assign_defaults(session)
    person = %{Cases.get_person(id) | originator: socket.assigns.current_user.id}
    changeset = person |> Cases.change_person(%{}) |> hard_code_gender_identity()

    {
      :ok,
      assign(
        socket,
        changeset: changeset,
        person: person
      )
    }
  end

  defp hard_code_gender_identity(%{data: data} = changeset) do
    %{changeset | data: %{data | gender_identity: ["Female"]}}
  end

  def gender_identity_options() do
    [
      "Declined to answer",
      "Female",
      "Transgender woman/trans woman/male-to-female (MTF)",
      "Male",
      "Transgender man/trans man/female-to-male (FTM)",
      "Genderqueer/gender nonconforming neither exclusively male nor female",
      "Additional gender category (or other)"
    ]
  end

  def gender_identity_is_checked() do
  end
end
