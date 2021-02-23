defmodule EpicenterWeb.ProfileEditLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [plus_icon: 0, arrow_down_icon: 0, back_icon: 0, trash_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [assign_defaults: 1, assign_page_title: 2, authenticate_user: 2, noreply: 1, ok: 1]
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]
  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.DateParser
  alias Epicenter.Extra
  alias Epicenter.Validation
  alias EpicenterWeb.Format
  alias EpicenterWeb.Presenters.GeographyPresenter

  defmodule FormData do
    use Ecto.Schema

    embedded_schema do
      field :first_name, :string
      field :last_name, :string
      field :dob, :string
      field :preferred_language, :string
      field :other_specified_language, :string
      embeds_many :phones, Epicenter.Cases.Phone, on_replace: :delete
      embeds_many :emails, Epicenter.Cases.Email, on_replace: :delete
      embeds_many :addresses, Epicenter.Cases.Address, on_replace: :delete
    end
  end

  def mount(%{"id" => id}, session, socket) do
    socket = socket |> authenticate_user(session)

    person =
      Cases.get_person(id, socket.assigns.current_user)
      |> Cases.preload_emails()
      |> Cases.preload_phones()
      |> Cases.preload_addresses()
      |> Cases.preload_demographics()

    demographic = Cases.Person.coalesce_demographics(person)

    changeset =
      %FormData{
        first_name: demographic.first_name,
        last_name: demographic.last_name,
        dob: with(%Date{} = date <- demographic.dob, do: Format.date(date)),
        preferred_language: demographic.preferred_language,
        other_specified_language: "",
        phones: person.phones,
        emails: person.emails,
        addresses: person.addresses
      }
      |> update(%{})

    socket
    |> assign_defaults()
    |> assign_page_title("#{Format.person(person)} (edit)")
    |> assign(changeset: changeset)
    |> assign(person: person)
    |> assign(preferred_language_is_other: false)
    |> ok()
  end

  def handle_event("add-address", _value, socket) do
    existing_addresses = socket.assigns.changeset |> Extra.Changeset.get_field_from_changeset(:addresses)
    addresses = existing_addresses |> Enum.concat([Cases.change_address(%Cases.Address{}, %{})])

    changeset = socket.assigns.changeset |> Ecto.Changeset.put_embed(:addresses, addresses)
    socket |> assign(changeset: changeset |> Extra.Changeset.clear_validation_errors()) |> noreply()
  end

  def handle_event("add-email", _value, socket) do
    existing_emails = socket.assigns.changeset |> Extra.Changeset.get_field_from_changeset(:emails)
    emails = existing_emails |> Enum.concat([Cases.change_email(%Cases.Email{}, %{})])

    changeset = socket.assigns.changeset |> Ecto.Changeset.put_embed(:emails, emails)
    socket |> assign(changeset: changeset |> Extra.Changeset.clear_validation_errors()) |> noreply()
  end

  def handle_event("add-phone", _value, socket) do
    existing_phones = socket.assigns.changeset |> Extra.Changeset.get_field_from_changeset(:phones)
    phones = existing_phones |> Enum.concat([Cases.change_phone(%Cases.Phone{}, %{})])

    changeset = socket.assigns.changeset |> Ecto.Changeset.put_embed(:phones, phones)
    socket |> assign(changeset: changeset |> Extra.Changeset.clear_validation_errors()) |> noreply()
  end

  def handle_event("form-change", %{"form_data" => %{"preferred_language" => "Other"} = form_params}, socket) do
    socket
    |> assign(preferred_language_is_other: true)
    |> assign(
      changeset:
        socket.assigns.changeset
        |> update(form_params)
    )
    |> noreply()
  end

  def handle_event("form-change", %{"form_data" => form_params}, socket) do
    socket
    |> assign(preferred_language_is_other: false)
    |> assign(
      changeset:
        socket.assigns.changeset
        |> update(form_params)
    )
    |> noreply()
  end

  def handle_event("remove-address", %{"address-index" => address_index_param}, socket) do
    address_index = address_index_param |> Euclid.Extra.String.to_integer()

    existing_addresses = socket.assigns.changeset |> Extra.Changeset.get_field_from_changeset(:addresses)
    addresses = existing_addresses |> List.delete_at(address_index)

    changeset = socket.assigns.changeset |> Ecto.Changeset.put_embed(:addresses, addresses)
    {:noreply, assign(socket, changeset: changeset |> Extra.Changeset.clear_validation_errors())}
  end

  def handle_event("remove-email", %{"email-index" => email_index_param}, socket) do
    email_index = email_index_param |> Euclid.Extra.String.to_integer()

    existing_emails = socket.assigns.changeset |> Extra.Changeset.get_field_from_changeset(:emails)
    emails = existing_emails |> List.delete_at(email_index)

    changeset = socket.assigns.changeset |> Ecto.Changeset.put_embed(:emails, emails)
    {:noreply, assign(socket, changeset: changeset |> Extra.Changeset.clear_validation_errors())}
  end

  def handle_event("remove-phone", %{"phone-index" => phone_index_param}, socket) do
    phone_index = phone_index_param |> Euclid.Extra.String.to_integer()

    existing_phones = socket.assigns.changeset |> Extra.Changeset.get_field_from_changeset(:phones)
    phones = existing_phones |> List.delete_at(phone_index)

    changeset = socket.assigns.changeset |> Ecto.Changeset.put_embed(:phones, phones)
    {:noreply, assign(socket, changeset: changeset |> Extra.Changeset.clear_validation_errors())}
  end

  def handle_event("save", %{"form_data" => form_params}, socket) do
    changeset =
      socket.assigns.changeset
      |> update(form_params)
      |> validate()

    with {:validation_step, []} <- {:validation_step, changeset.errors},
         person_params = translate_form_data_to_person_params(changeset, socket.assigns.person.demographics),
         {:ok, person} <-
           Cases.update_person(
             socket.assigns.person,
             {person_params,
              %AuditLog.Meta{
                author_id: socket.assigns.current_user.id,
                reason_action: AuditLog.Revision.update_profile_action(),
                reason_event: AuditLog.Revision.edit_profile_saved_event()
              }}
           ) do
      {:noreply, socket |> push_redirect(to: Routes.profile_path(socket, EpicenterWeb.ProfileLive, person))}
    else
      {:validation_step, _} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:error, %Ecto.Changeset{} = _} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp upsert_only_form_demographics(demographics, changeset) do
    # find the most recent(highest precedence form demographic and update that one)
    # otherwise, add a new form demographic

    {_, latest_form_demographic_id} =
      Enum.reduce(
        demographics,
        {~U[2019-01-01 00:00:00Z], nil},
        fn demographic, {latest_inserted_at, form_demographic_id} ->
          if demographic.source == "form" && DateTime.compare(demographic.inserted_at, latest_inserted_at) == :gt do
            {demographic.inserted_at, demographic.id}
          else
            {latest_inserted_at, form_demographic_id}
          end
        end
      )

    non_changing_demographics = demographics |> Enum.reject(&(&1.id == latest_form_demographic_id)) |> Euclid.Extra.Enum.pluck([:id])
    changing_form_demographic = demographics |> Enum.find(&(&1.id == latest_form_demographic_id))

    non_changing_demographics ++
      [
        changeset.changes
        |> update_if_present(:dob, &update_dob/1)
        |> rewrite_preferred_language(changeset)
        |> Map.merge(%{id: if(changing_form_demographic, do: changing_form_demographic.id, else: nil), source: "form"})
      ]
  end

  defp update_dob(nil), do: nil
  defp update_dob(""), do: nil
  defp update_dob(dob), do: DateParser.parse_mm_dd_yyyy!(dob)

  defp rewrite_preferred_language(map, changeset) do
    with {_, "Other"} <- Ecto.Changeset.fetch_field(changeset, :preferred_language),
         {_, value} <- Ecto.Changeset.fetch_field(changeset, :other_specified_language) do
      Map.put(map, :preferred_language, value)
    else
      _ -> map
    end
  end

  defp translate_form_data_to_person_params(changeset, demographics) do
    changeset.changes
    |> Map.merge(%{demographics: upsert_only_form_demographics(demographics, changeset)})
    |> update_if_present(:emails, fn emails -> Enum.map(emails, &translate_form_embed_to_person_params/1) end)
    |> update_if_present(:addresses, fn addresses -> Enum.map(addresses, &translate_form_embed_to_person_params/1) end)
    |> update_if_present(:phones, fn phones -> Enum.map(phones, &translate_form_embed_to_person_params/1) end)
    |> remove_blank_addresses()
    |> remove_blank_email_addresses()
    |> remove_blank_phone_numbers()
  end

  defp translate_form_embed_to_person_params(%{data: data, action: :delete}), do: %{id: data.id, delete: true}
  defp translate_form_embed_to_person_params(%{data: data, action: :replace}), do: %{id: data.id, delete: true}
  defp translate_form_embed_to_person_params(%{data: data, changes: changes}), do: %{id: data.id} |> Map.merge(changes)

  defp update(changeset, form_params) do
    changeset
    |> Ecto.Changeset.cast(form_params, [:first_name, :last_name, :dob, :preferred_language, :other_specified_language])
    |> Ecto.Changeset.cast_embed(:addresses, with: &Cases.Address.changeset/2)
    |> Ecto.Changeset.cast_embed(:emails, with: &Cases.Email.changeset/2)
    |> Ecto.Changeset.cast_embed(:phones, with: &Cases.Phone.changeset/2)
  end

  defp validate(changeset) do
    changeset
    |> Map.put(:action, :insert)
    |> Ecto.Changeset.validate_change(:dob, :date_format, fn
      :dob, nil ->
        []

      :dob, "" ->
        []

      :dob, value ->
        case DateParser.parse_mm_dd_yyyy(value) do
          {:ok, _date} -> []
          _ -> [dob: Validation.invalid_date_format_message()]
        end
    end)
    |> Epicenter.PhiValidation.validate_phi(:demographic)
  end

  # # #

  def clean_up_languages(%{"demographics" => %{"0" => demographics}} = person_params),
    do: put_in(person_params, ["demographics", "0"], clean_up_languages(demographics))

  def clean_up_languages(%{"preferred_language" => "Other"} = demographic_params),
    do: demographic_params |> Map.put("preferred_language", demographic_params |> Map.get("other_specified_language"))

  def clean_up_languages(person_params), do: person_params

  def has_field?(changeset, field) do
    case changeset |> Ecto.Changeset.fetch_field(field) do
      :error -> false
      {_, []} -> false
      _ -> true
    end
  end

  def phone_types(),
    do: [{"Unknown", nil}, {"Cell", "cell"}, {"Home", "home"}, {"Work", "work"}]

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

  def remove_blank_email_addresses(%{emails: email_params} = person_params) do
    updated_email_params =
      email_params
      |> Enum.reject(fn
        %{id: nil, address: address} -> Euclid.Exists.blank?(address)
        %{id: nil} -> true
        _ -> false
      end)
      |> Enum.map(fn
        %{id: id, address: address} = attrs -> if(Euclid.Exists.blank?(address), do: %{id: id, delete: true}, else: attrs)
        other -> other
      end)

    person_params |> Map.put(:emails, updated_email_params)
  end

  def remove_blank_email_addresses(person_params),
    do: person_params

  def remove_blank_phone_numbers(%{phones: phone_params} = person_params) do
    updated_phone_params =
      phone_params
      |> Enum.reject(fn
        %{id: nil, number: number} -> Euclid.Exists.blank?(number)
        %{id: nil} -> true
        _ -> false
      end)
      |> Enum.map(fn
        %{id: id, number: nil} -> %{id: id, delete: true}
        %{id: id, number: ""} -> %{id: id, delete: true}
        other -> other
      end)

    person_params |> Map.put(:phones, updated_phone_params)
  end

  def remove_blank_phone_numbers(person_params),
    do: person_params

  def remove_blank_addresses(%{addresses: address_params} = person_params) do
    updated_address_params =
      address_params
      |> Enum.reject(fn address ->
        Euclid.Exists.blank?(Map.get(address, :street)) and Euclid.Exists.blank?(Map.get(address, :city)) and
          Euclid.Exists.blank?(Map.get(address, :postal_code)) and Euclid.Exists.blank?(Map.get(address, :id))
      end)

    person_params |> Map.put(:addresses, updated_address_params)
  end

  def remove_blank_addresses(person_params),
    do: person_params

  # # #

  defp update_if_present(map, field, func) do
    if Map.has_key?(map, field) do
      Map.update!(map, field, func)
    else
      map
    end
  end
end
