defmodule EpicenterWeb.ResolveConflictsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 2, assign_page_title: 2, authenticate_user: 2, ok: 1]

  alias Epicenter.Cases
  alias EpicenterWeb.Form
  alias EpicenterWeb.Forms.ResolveConflictsForm

  def mount(%{"person_ids" => comma_separated_person_ids} = _params, session, socket) do
    socket = socket |> authenticate_user(session)

    person_ids = String.split(comma_separated_person_ids, ",")
    merge_conflicts = Epicenter.Cases.Merge.merge_conflicts(person_ids, socket.assigns.current_user)

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
    Form.new(form)
    |> Form.line(&Form.radio_button_list(&1, :first_name, "Choose the correct first name", merge_conflicts.unique_first_names, span: 8))
    |> Form.safe()
  end
end
