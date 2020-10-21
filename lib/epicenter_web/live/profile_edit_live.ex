defmodule EpicenterWeb.ProfileEditLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView, only: [plus_icon: 0, arrow_down_icon: 0, back_icon: 0, trash_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [authenticate_user: 2, assign_page_title: 2, noreply: 1, ok: 1]
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]
  import EpicenterWeb.ConfirmationModal, only: [abandon_changes_confirmation_text: 0]

  alias Epicenter.AuditLog
  alias Epicenter.Cases
  alias Epicenter.DateParser
  alias Epicenter.Extra
  alias Epicenter.Format

  defmodule FormData do
    use Ecto.Schema

    embedded_schema do
      field :first_name, :string
      field :last_name, :string
      field :dob, :string
      field :preferred_language, :string
      field :other_specified_language, :string
      field :form_demographic_id, :string
      embeds_many :phones, Epicenter.Cases.Phone, on_replace: :delete
      embeds_many :emails, Epicenter.Cases.Email, on_replace: :delete
      embeds_many :addresses, Epicenter.Cases.Address, on_replace: :delete
    end
  end

  def mount(%{"id" => id}, session, socket) do
    socket = socket |> authenticate_user(session)

    person =
      Cases.get_person(id)
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
        form_demographic_id: demographic.id,
        other_specified_language: "",
        phones: person.phones,
        emails: person.emails,
        addresses: person.addresses
      }
      |> update(%{})

    socket
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

    update_dob = fn
      nil -> nil
      "" -> nil
      dob -> DateParser.parse_mm_dd_yyyy!(dob)
    end

    rewrite_preferred_language = fn map, changeset ->
      with {_, "Other"} <- Ecto.Changeset.fetch_field(changeset, :preferred_language),
           {_, value} <- Ecto.Changeset.fetch_field(changeset, :other_specified_language) do
        Map.put(map, :preferred_language, value)
      else
        _ -> map
      end
    end

    with {:valid, []} <- {:valid, changeset.errors},
         person_params =
           changeset.changes
           |> Map.merge(%{
             demographics: [
               changeset.changes
               |> update_if_present(:dob, update_dob)
               |> rewrite_preferred_language.(changeset)
               |> Map.merge(%{id: Extra.Changeset.get_field_from_changeset(changeset, :form_demographic_id)})
             ]
           })
           |> update_if_present(:emails, fn emails ->
             Enum.map(emails, fn
               %{data: data, action: :delete} -> %{id: data.id, delete: true}
               %{data: data, action: :replace} -> %{id: data.id, delete: true}
               %{data: data, changes: changes} -> %{id: data.id} |> Map.merge(changes)
             end)
           end)
           |> update_if_present(:addresses, fn addresses ->
             Enum.map(addresses, fn
               %{data: data, action: :delete} -> %{id: data.id, delete: true}
               %{data: data, action: :replace} -> %{id: data.id, delete: true}
               %{data: data, changes: changes} -> %{id: data.id} |> Map.merge(changes)
             end)
           end)
           |> update_if_present(:phones, fn phones ->
             Enum.map(phones, fn
               %{data: data, action: :delete} -> %{id: data.id, delete: true}
               %{data: data, action: :replace} -> %{id: data.id, delete: true}
               %{data: data, changes: changes} -> %{id: data.id} |> Map.merge(changes)
             end)
           end)
           |> remove_blank_addresses()
           |> remove_blank_email_addresses()
           |> remove_blank_phone_numbers(),
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
      {:valid, _} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

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
          _ -> [dob: "please enter dates as mm/dd/yyyy"]
        end
    end)
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

  def states() do
    ~w{AL AK AS AZ AR CA CO CT DE DC FL GA GO HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MP MT NE NV NH NJ NM NY NC ND OH OK OR PA PR RI SC SD TN TX UT VT VA VI WA WV WI WY}
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
          Euclid.Exists.blank?(Map.get(address, :postal_code))
      end)

    person_params |> Map.put(:addresses, updated_address_params)
  end

  def remove_blank_addresses(person_params),
    do: person_params

  # # #

  def confirmation_prompt(nil), do: nil

  def confirmation_prompt(changeset) do
    if changeset.changes == %{}, do: nil, else: abandon_changes_confirmation_text()
  end

  defp update_if_present(map, field, func) do
    if Map.has_key?(map, field) do
      Map.update!(map, field, func)
    else
      map
    end
  end
end
