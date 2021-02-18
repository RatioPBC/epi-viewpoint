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
    IO.inspect params, label: "params"
    IO.inspect socket.assigns.form_changeset, label: "foof"
    # "street" field is currently getting dropped in update
    changeset = update(socket.assigns.form_changeset, params)
    place_params = PlaceForm.place_attrs(changeset)

    IO.inspect(place_params, label: "place param")

    with {:validation_step, []} <- {:validation_step, changeset.errors},
         {:ok, _place} <-
           Cases.create_place(
             {place_params,
              %AuditLog.Meta{
                author_id: socket.assigns.current_user.id,
                reason_action: AuditLog.Revision.create_place_action(),
                reason_event: AuditLog.Revision.create_place_event()
              }}
           ) do
      socket
      |> push_redirect(to: Routes.people_path(socket, EpicenterWeb.PeopleLive))
      |> noreply()
    else
      {:validation_step, _} ->
        socket |> assign_form_changeset(changeset) |> noreply()

        # {:place, {:error, form_changeset}} ->
        #   socket
        #   |> assign_form_changeset(form_changeset, "An unexpected error occurred")
        #   |> noreply()
    end
  end

  defp update(changeset, params) do
    IO.inspect(changeset)

    changeset
    |> Ecto.Changeset.cast(params, [:name, :street, :type, :contact_name, :contact_phone, :contact_email])

    # |> Ecto.Changeset.cast_embed(:place, with: &PlaceForm.changeset/2)
    # |> Ecto.Changeset.cast_embed(:place, with: &Cases.Place.changeset/2)
    # |> Ecto.Changeset.cast_embed(:place_address, with: &Cases.PlaceAddress.changeset/2)
  end

  defp create_place(socket, place_attrs) do
    Cases.create_place(
      {place_attrs,
       %AuditLog.Meta{
         author_id: socket.assigns.current_user.id,
         reason_action: AuditLog.Revision.create_place_action(),
         reason_event: AuditLog.Revision.create_place_event()
       }}
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
