defmodule EpicenterWeb.CaseInvestigationDiscontinueLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.Cases
  alias EpicenterWeb.Form

  defmodule DiscontinueForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field :reason
    end

    def changeset() do
      %DiscontinueForm{}
      |> cast(%{}, [])
    end
  end

  def mount(%{"id" => person_id}, session, socket) do
    socket = socket |> authenticate_user(session)
    person = Cases.get_person(person_id)

    socket
    |> assign_page_title("Discontinue Case Investigation")
    |> assign(form_changeset: DiscontinueForm.changeset())
    |> assign(person: person)
    |> ok()
  end

  def handle_event("save", %{}, socket) do
    # |> push_redirect(to: Routes.profile_path(socket, EpicenterWeb.ProfileLive, person))}
    noreply(socket)
  end

  def reasons() do
    ["Unable to reach", "Transferred to another jurisdiction", "Deceased"]
  end

  # # #

  def discontinue_form_builder(changeset) do
    Form.new(changeset)
    |> Form.line(fn line ->
      line
      |> Form.radio_button_list(:reason, "Reason", reasons(), other: "Other")
    end)
    |> Form.safe()
  end
end
