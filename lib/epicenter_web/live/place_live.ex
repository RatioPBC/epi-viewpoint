defmodule EpicenterWeb.PlaceLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_form_changeset: 2, assign_form_changeset: 3, assign_page_title: 2, authenticate_user: 2, ok: 1, noreply: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.Place
  alias Epicenter.AuditLog
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.PlaceForm

  def mount(_params, session, socket) do
    socket = socket |> authenticate_user(session)
    place = %Place{}
    changeset = PlaceForm.changeset(%{}, %{})

    socket
    |> assign_defaults()
    |> assign_page_title("New place")
    |> assign(place: place)
    |> assign_form_changeset(changeset)
    |> ok()
  end

  def handle_event("form-change", %{"place_form" => _place_params}, socket) do
    socket |> noreply()
  end

  def handle_event("save", %{"place_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- PlaceForm.changeset(socket.assigns.place, params),
         {:form, {:ok, place_attrs}} <- {:form, PlaceForm.place_attrs(form_changeset)},
         {:form, {:ok, place_address_attrs}} = {:form, PlaceForm.place_address_attrs(form_changeset)},
         {:place, {:ok, _place}} <- {:place, create_place(socket, place_attrs, place_address_attrs)} do
      socket
      |> push_redirect(to: Routes.people_path(socket, EpicenterWeb.PeopleLive))
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:place, {:error, _, _}} ->
        socket
        |> assign_form_changeset(PlaceForm.changeset(socket.assigns.place, params), "An unexpected error occurred")
        |> noreply()
    end
  end

  defp create_place(socket, place_attrs, place_address_attrs) do
    Cases.create_place(
      place_attrs,
      place_address_attrs,
      %AuditLog.Meta{
        author_id: socket.assigns.current_user.id,
        reason_action: AuditLog.Revision.create_place_action(),
        reason_event: AuditLog.Revision.create_place_event()
      }
    )
  end

  @place_types [
    {"", ""},
    {"House/single family home", "single_family_home"},
    {"Apartment", "apartment"},
    {"Mobile home", "mobile_home"},
    {"Hotel/motel/hostel", "hotel"},
    {"Homeless/shelter", "homeless_shelter"},
    {"Daycare", "daycare"},
    {"School", "school"},
    {"College", "college"},
    {"Workplace", "workplace"},
    {"Airport", "airport"},
    {"Transit (e.g. bus/train/subway)", "transit"},
    {"Military", "military"},
    {"Doctor's office", "doctors_office"},
    {"Hospital ward", "hospital_ward"},
    {"Emergency department/Urgent care", "emergency_department"},
    {"Hospital outpatient facility", "hospital_outpatient_facility"},
    {"Long-term care facility", "long_term_care_facility"},
    {"Correctional facility/jail", "correctional_facility"},
    {"Place of worship", "place_of_worship"},
    {"Laboratory", "laboratory"},
    {"Restaurant", "restaurant"},
    {"Retail", "retail"},
    {"Other", "other"}
  ]

  def place_form_builder(form) do
    Form.new(form)
    |> Form.line(&Form.text_field(&1, :name, "Location name", span: 4))
    |> Form.line(&Form.text_field(&1, :street, "Address", span: 4))
    |> Form.line(&Form.select(&1, :type, "Type of place", @place_types, span: 4))
    |> Form.line(&Form.text_field(&1, :contact_name, "Name of main contact", span: 4))
    |> Form.line(&Form.text_field(&1, :contact_phone, "Phone", span: 4))
    |> Form.line(&Form.text_field(&1, :contact_email, "Email", span: 4))
    |> Form.line(&Form.save_button(&1))
    |> Form.safe()
  end
end
