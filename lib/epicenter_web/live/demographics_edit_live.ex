defmodule EpicenterWeb.DemographicsEditLive do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases
  alias EpicenterWeb.Session

  def mount(%{"id" => id}, _session, socket) do
    person = %{Cases.get_person(id) | originator: Session.get_current_user()}
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
