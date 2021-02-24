defmodule EpicenterWeb.ResolveConflictsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [back_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]

  alias Epicenter.Cases.Merge
  alias Epicenter.DateParser
  alias EpicenterWeb.Form
  alias EpicenterWeb.Format
  alias EpicenterWeb.Forms.ResolveConflictsForm

  def mount(%{"id" => person_id, "duplicate_person_ids" => comma_separated_duplicate_person_ids} = _params, session, socket) do
    socket = socket |> authenticate_user(session)

    duplicate_person_ids = String.split(comma_separated_duplicate_person_ids, ",")
    person_ids = [person_id] ++ duplicate_person_ids
    merge_fields = [{:first_name, :string}, {:dob, :date}, {:preferred_language, :string}]
    merge_conflicts = Epicenter.Cases.Merge.merge_conflicts(person_ids, socket.assigns.current_user, merge_fields)

    socket
    |> assign_defaults(body_class: "body-background-none")
    |> assign_page_title("Resolve Conflicts")
    |> assign(:merge_conflicts, merge_conflicts)
    |> assign(:has_merge_conflicts?, Merge.has_merge_conflicts?(merge_conflicts))
    |> assign(:form_changeset, ResolveConflictsForm.changeset(merge_conflicts, %{}))
    |> assign(:person_id, person_id)
    |> assign(:duplicate_person_ids, duplicate_person_ids)
    |> ok()
  end

  def handle_event("form-change", %{"resolve_conflicts_form" => form_params}, socket) do
    socket
    |> assign(:form_changeset, ResolveConflictsForm.changeset(socket.assigns.merge_conflicts, form_params))
    |> noreply()
  end

  def handle_event("save", %{"resolve_conflicts_form" => form_params}, socket) do
    merge_conflict_resolutions =
      %{
        first_name: form_params["first_name"],
        dob:
          case form_params["dob"] do
            nil -> nil
            dob -> dob |> DateParser.parse_mm_dd_yyyy!()
          end,
        preferred_language: form_params["preferred_language"]
      }
      |> Enum.filter(fn {_k, v} -> v != nil end)
      |> Enum.into(%{})

    Merge.merge(
      socket.assigns.duplicate_person_ids,
      into: socket.assigns.person_id,
      merge_conflict_resolutions: merge_conflict_resolutions,
      current_user: socket.assigns.current_user
    )

    socket
    |> push_redirect(to: "#{Routes.profile_path(socket, EpicenterWeb.ProfileLive, socket.assigns.person_id)}")
    |> noreply()
  end

  def handle_event("save", _params, socket) do
    handle_event("save", %{"resolve_conflicts_form" => %{}}, socket)
  end

  # # #

  def form_builder(form, merge_conflicts, valid_changeset?) do
    formatted_dates = merge_conflicts.dob |> Enum.map(&Format.date/1)

    Form.new(form)
    |> add_line(:first_name, "Choose the correct first name", merge_conflicts.first_name)
    |> add_line(:dob, "Choose the correct date of birth", formatted_dates)
    |> add_line(:preferred_language, "Choose the correct preferred language", merge_conflicts.preferred_language)
    |> Form.line(&Form.save_button(&1, title: "Merge", disabled: !valid_changeset?))
    |> Form.safe()
  end

  def add_line(form, _field, _label, conflicts) when conflicts == [], do: form

  def add_line(form, field, label, conflicts) do
    Form.line(form, &Form.radio_button_list(&1, field, label, conflicts, span: 8))
  end
end
