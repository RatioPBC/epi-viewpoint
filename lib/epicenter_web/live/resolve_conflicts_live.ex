defmodule EpicenterWeb.ResolveConflictsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, authenticate_user: 2, ok: 1]

  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Format
  alias EpicenterWeb.Forms.ResolveConflictsForm

  def mount(%{"person_ids" => comma_separated_person_ids} = _params, session, socket) do
    socket = socket |> authenticate_user(session)

    person_ids = String.split(comma_separated_person_ids, ",")
    merge_fields = [{:first_name, :string}, {:dob, :date}, {:preferred_language, :string}]
    merge_conflicts = Epicenter.Cases.Merge.merge_conflicts(person_ids, socket.assigns.current_user, merge_fields)

    socket
    |> assign_defaults(body_class: "body-background-none")
    |> assign_page_title("Resolve Conflicts")
    |> assign(:merge_conflicts, merge_conflicts)
    |> assign(:form_changeset, ResolveConflictsForm.model_to_form_changeset(merge_conflicts))
    |> assign_person_ids(comma_separated_person_ids)
    |> ok()
  end

  # # #

  defp assign_person_ids(socket, comma_separated_person_ids) do
    person_ids = String.split(comma_separated_person_ids, ",")
    people = Cases.get_people(person_ids, socket.assigns.current_user)

    socket
    |> assign(:people, people)
  end

  def form_builder(form, merge_conflicts) do
    formatted_dates = merge_conflicts.dob |> Enum.map(&Format.date/1)

    Form.new(form)
    |> add_line(:first_name, "Choose the correct first name", merge_conflicts.first_name)
    |> add_line(:dob, "Choose the correct date of birth", formatted_dates)
    |> add_line(:preferred_language, "Choose the correct preferred language", merge_conflicts.preferred_language)
    |> Form.safe()
  end

  def add_line(form, _field, _label, conflicts) when conflicts == [], do: form

  def add_line(form, field, label, conflicts) do
    Form.line(form, &Form.radio_button_list(&1, field, label, conflicts, span: 8))
  end
end
