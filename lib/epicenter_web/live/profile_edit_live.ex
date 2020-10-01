defmodule EpicenterWeb.ProfileEditLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [arrow_down_icon: 0, arrow_right_icon: 2, trash_icon: 0]

  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias Epicenter.DateParser
  alias Epicenter.Extra
  alias EpicenterWeb.Session

  def mount(%{"id" => id}, _session, socket) do
    person = %{Cases.get_person(id) | originator: Session.get_current_user()} |> Cases.preload_emails()
    changeset = person |> Cases.change_person(%{})

    {
      :ok,
      assign(
        socket,
        changeset: update_dob_field_for_display(changeset),
        person: person,
        preferred_language_is_other: false
      )
    }
  end

  def handle_event("add-email", _value, socket) do
    person = socket.assigns.person
    existing_emails = socket.assigns.changeset.changes |> Map.get(:emails, socket.assigns.person.emails)
    emails = existing_emails |> Enum.concat([Cases.change_email(%Cases.Email{person_id: person.id}, %{})])
    changeset = socket.assigns.changeset |> Ecto.Changeset.put_assoc(:emails, emails)
    {:noreply, assign(socket, changeset: changeset |> Extra.Changeset.clear_validation_errors())}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    person_params = person_params |> update_dob_field_for_changeset() |> clean_up_languages() |> remove_blank_email_addresses()

    case Cases.update_person(
           socket.assigns.person,
           {person_params,
            %{
              author_id: Session.get_current_user().id,
              reason_action: Revision.update_profile_action(),
              reason_event: Revision.edit_profile_saved_event()
            }}
         ) do
      {:ok, person} ->
        {:noreply, socket |> push_redirect(to: Routes.profile_path(socket, EpicenterWeb.ProfileLive, person))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, update_dob_field_for_display(changeset))}
    end
  end

  def handle_event("form-change", %{"person" => %{"preferred_language" => "Other"} = person_params}, socket) do
    socket |> assign(preferred_language_is_other: true) |> reassign_changeset(person_params) |> noreply()
  end

  def handle_event("form-change", %{"person" => person_params} = _params, socket) do
    socket |> assign(preferred_language_is_other: false) |> reassign_changeset(person_params) |> noreply()
  end

  defp reassign_changeset(socket, person_params) do
    person_params = person_params |> update_dob_field_for_changeset() |> clean_up_languages()

    changeset =
      socket.assigns.person
      |> Cases.change_person(person_params)
      |> Map.put(:action, :insert)

    assign(socket, changeset: changeset |> update_dob_field_for_display() |> Extra.Changeset.clear_validation_errors())
  end

  def preferred_languages(current \\ nil) do
    has_current = Euclid.Exists.present?(current)

    first = [
      {"English", "English"},
      {"Spanish", "Spanish"}
    ]

    middle =
      [
        {"Arabic", "Arabic"},
        {"Bengali", "Bengali"},
        {"Chinese (Cantonese)", "Chinese (Cantonese)"},
        {"Chinese (Mandarin)", "Chinese (Mandarin)"},
        {"French", "French"},
        {"Haitian Creole", "Haitian Creole"},
        {"Hebrew", "Hebrew"},
        {"Hindi", "Hindi"},
        {"Italian", "Italian"},
        {"Korean", "Korean"},
        {"Polish", "Polish"},
        {"Russian", "Russian"},
        {"Swahili", "Swahili"},
        {"Yiddish", "Yiddish"}
      ]
      |> case do
        languages when has_current -> [{current, current} | languages]
        languages -> languages
      end
      |> Enum.sort_by(&elem(&1, 0))

    last = [{"Other", "Other"}]

    (first ++ middle ++ last) |> Enum.uniq()
  end

  def clean_up_languages(%{"preferred_language" => "Other"} = person_params),
    do: person_params |> Map.put("preferred_language", person_params |> Map.get("other_specified_language"))

  def clean_up_languages(person_params), do: person_params

  def remove_blank_email_addresses(%{"emails" => email_params} = person_params) do
    updated_email_params =
      email_params
      |> Enum.reject(fn {_index, %{"address" => address}} -> Euclid.Exists.blank?(address) end)
      |> Map.new()

    person_params |> Map.put("emails", updated_email_params)
  end

  def remove_blank_email_addresses(person_params),
    do: person_params

  def has_emails(changeset) do
    case changeset |> Ecto.Changeset.fetch_field(:emails) do
      :error -> false
      {_, []} -> false
      _ -> true
    end
  end

  # # #

  # replace human readable dates with Date objects
  defp update_dob_field_for_changeset(person_params) do
    case DateParser.parse_mm_dd_yyyy(person_params["dob"]) do
      {:ok, date} -> %{person_params | "dob" => date}
      {:error, _} -> person_params
    end
  end

  defp update_dob_field_for_display(changeset) do
    if changeset.errors |> Keyword.has_key?(:dob) do
      Extra.Changeset.rewrite_changeset_error_message(changeset, :dob, "please enter dates as mm/dd/yyyy")
    else
      reformat_date(changeset, :dob)
    end
  end

  defp reformat_date(changeset, field) do
    case Ecto.Changeset.fetch_field(changeset, field) do
      {:error} -> changeset
      {_, date} -> Ecto.Changeset.put_change(changeset, field, Extra.Date.render(date))
    end
  end

  defp noreply(socket),
    do: {:noreply, socket}
end
