defmodule Epicenter.Cases.Person do
  use Ecto.Schema

  import Ecto.Changeset
  alias Epicenter.Accounts.User
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Email
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Phone
  alias Epicenter.Extra

  @optional_attrs ~w{assigned_to_id tid archived_at archived_by_id}a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "people" do
    field :archived_at, :utc_datetime
    field :merged_at, :utc_datetime
    field :seq, :integer, read_after_writes: true
    field :tid, :string

    timestamps(type: :utc_datetime)

    belongs_to :archived_by, User
    belongs_to :assigned_to, User
    belongs_to :merged_by, User
    belongs_to :merged_into, Person
    has_many :demographics, Demographic
    has_many :addresses, Address
    has_many :case_investigations, CaseInvestigation
    has_many :emails, Email, on_replace: :delete
    has_many :contact_investigations, ContactInvestigation, on_replace: :delete, foreign_key: :exposed_person_id
    has_many :lab_results, LabResult
    has_many :phones, Phone, on_replace: :delete
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      put_field_if_loaded = fn person_attrs, value, field_name ->
        case Map.get(value, field_name) do
          %Ecto.Association.NotLoaded{} -> person_attrs
          _ -> Map.put(person_attrs, field_name, Map.get(value, field_name))
        end
      end

      person_attrs = Map.take(value, [:id] ++ Person.optional_attrs())

      person_attrs = put_field_if_loaded.(person_attrs, value, :emails)
      person_attrs = put_field_if_loaded.(person_attrs, value, :lab_results)
      person_attrs = put_field_if_loaded.(person_attrs, value, :phones)

      Jason.Encode.map(person_attrs, opts)
    end
  end

  def assignment_changeset(person, nil = _user), do: person |> changeset(%{assigned_to_id: nil})
  def assignment_changeset(person, %User{} = user), do: person |> changeset(%{assigned_to_id: user.id})

  def changeset(person, attrs) do
    person
    |> cast(Enum.into(attrs, %{}), @optional_attrs)
    |> cast_demographics_assoc(attrs)
    |> cast_assoc(:addresses, with: &Address.changeset/2)
    |> cast_assoc(:emails, with: &Email.changeset/2)
    |> cast_phones_assoc(attrs)
  end

  def changeset_for_archive(person, %User{id: archiving_user_id}) do
    person
    |> cast(%{archived_by_id: archiving_user_id, archived_at: DateTime.utc_now()}, ~w{archived_by_id archived_at}a)
  end

  def changeset_for_unarchive(person_or_changeset) do
    person_or_changeset
    |> cast(%{archived_by_id: nil, archived_at: nil}, ~w{archived_by_id archived_at}a)
  end

  defp cast_demographics_assoc(changeset, attrs) do
    changeset = changeset |> cast_assoc(:demographics, with: &Demographic.changeset/2)

    attrs =
      with {:ok, form_demographic_params} <- Map.fetch(attrs, "form_demographic") do
        attrs
        |> Map.delete("form_demographic")
        |> Map.put(:form_demographic, form_demographic_params)
      else
        _ -> attrs
      end

    if Map.has_key?(attrs, :form_demographic) && get_change(changeset, :demographics) do
      throw("person changeset cannot contain both phones and additive phones because we haven't thought about which ones take precendence")
    end

    with {:ok, form_demographic_params} <- Map.fetch(attrs, :form_demographic) do
      existing_demographics = if changeset.data.id, do: changeset.data.demographics, else: []
      form_demographic = existing_demographics |> Enum.find(&(&1.source == "form"))

      changesets =
        existing_demographics
        |> Enum.map(fn demo ->
          if demo == form_demographic do
            Demographic.changeset(demo, form_demographic_params)
          else
            Demographic.changeset(demo, %{})
          end
        end)

      changesets =
        if form_demographic, do: changesets, else: changesets ++ [Demographic.changeset(%Demographic{source: "form"}, form_demographic_params)]

      changeset |> put_change(:demographics, changesets)
    else
      _ -> changeset
    end
  end

  defp cast_phones_assoc(changeset, attrs) do
    changeset = changeset |> cast_assoc(:phones, with: &Phone.changeset/2)

    attrs =
      with {:ok, additive_phone_params} <- Map.fetch(attrs, "additive_phone") do
        attrs
        |> Map.delete("additive_phone")
        |> Map.put(:additive_phone, additive_phone_params)
      else
        _ -> attrs
      end

    if Map.has_key?(attrs, :additive_phone) && get_change(changeset, :phones) do
      throw("person changeset cannot contain both phones and additive phones because we haven't thought about which ones take precendence")
    end

    with {:ok, additive_phone_params} when not is_nil(additive_phone_params) <- Map.fetch(attrs, :additive_phone),
         {:ok, existing_phones} <- extract_existing_phones(changeset.data),
         additive_phone_changeset = Phone.changeset(%Phone{}, additive_phone_params),
         new_phone_number <- get_change(additive_phone_changeset, :number),
         nil <- Enum.find(existing_phones, fn p -> p.number == new_phone_number end) do
      existing_phone_empty_changesets = existing_phones |> Enum.map(fn phone -> Phone.changeset(phone, %{}) end)

      changesets = existing_phone_empty_changesets ++ [additive_phone_changeset]

      changeset |> put_change(:phones, changesets)
    else
      :phones_are_not_preloaded -> throw("necessary phone numbers are not preloaded")
      _ -> changeset
    end
  end

  defp extract_existing_phones(%{id: person_id, phones: %Ecto.Association.NotLoaded{}}) when not is_nil(person_id) do
    :phones_are_not_preloaded
  end

  defp extract_existing_phones(%{phones: phones}) when is_list(phones) do
    {:ok, phones}
  end

  defp extract_existing_phones(%{id: nil}) do
    {:ok, []}
  end

  def coalesce_demographics(person) do
    Epicenter.Cases.Demographic.__schema__(:fields)
    |> Enum.reduce(%{}, fn field, data ->
      demographic =
        person.demographics
        |> Enum.filter(fn demo -> Map.get(demo, field) != nil end)
        |> Enum.sort(fn a, b ->
          case {{a.source, a.seq}, {b.source, b.seq}} do
            {{"form", seq1}, {"form", seq2}} -> seq2 <= seq1
            {{"form", _}, {_, _}} -> true
            {{_, _}, {"form", _}} -> false
            {{_, seq1}, {_, seq2}} -> seq2 >= seq1
          end
        end)
        |> Enum.at(0)

      case demographic do
        nil ->
          Map.put(data, field, nil)

        demographic ->
          Map.put(data, field, Map.get(demographic, field))
      end
    end)
  end

  def latest_case_investigation(person) do
    person
    |> Map.get(:case_investigations)
    |> Enum.sort_by(& &1.seq, :desc)
    |> Enum.max_by(& &1.inserted_at, Extra.Date.NilFirst, fn -> nil end)
  end

  def latest_contact_investigation(person) do
    person
    |> Map.get(:contact_investigations)
    |> Enum.sort_by(& &1.seq, :desc)
    |> Enum.max_by(& &1.inserted_at, Extra.Date.NilFirst, fn -> nil end)
  end

  def optional_attrs(), do: @optional_attrs

  defmodule Query do
    import Ecto.Query

    def all(), do: from(person in Person, order_by: [asc: person.seq])

    def assigned_to_id(query, user_id), do: query |> where([p], p.assigned_to_id == ^user_id)

    def reject_archived_people(query, true = _reject_archived), do: query |> where([p], is_nil(p.archived_at))
    def reject_archived_people(query, false = _reject_archived), do: query

    def filter_with_case_investigation(:all), do: Person.Query.all()

    def filter_with_contact_investigation(:with_contact_investigation), do: Person.Query.with_contact_investigation()
    def filter_with_contact_investigation(:with_quarantine_monitoring), do: Person.Query.with_contact_investigation_quarantine_monitoring()
    def filter_with_contact_investigation(:with_ongoing_interview), do: Person.Query.with_contact_investigation_ongoing_interview()
    def filter_with_contact_investigation(:with_pending_interview), do: Person.Query.with_contact_investigation_pending_interview()

    def get_people(ids), do: from(person in Person, where: person.id in ^ids, order_by: [asc: person.seq])

    @fields_to_replace_from_csv ~w{updated_at}a
    def opts_for_upsert(), do: [returning: true, on_conflict: {:replace, @fields_to_replace_from_csv}, conflict_target: :fingerprint]

    def with_demographic_field(query, field, value), do: query |> join(:inner, [p], d in assoc(p, :demographics), on: field(d, ^field) == ^value)

    def with_contact_investigation do
      from person in Person,
        join: contact_investigation in assoc(person, :contact_investigations),
        on: person.id == contact_investigation.exposed_person_id,
        order_by: [asc: person.seq]
    end

    def with_contact_investigation_quarantine_monitoring() do
      from person in Person,
        join: contact_investigation in assoc(person, :contact_investigations),
        on: person.id == contact_investigation.exposed_person_id,
        where:
          contact_investigation.interview_status == "completed" and
            contact_investigation.quarantine_monitoring_status in ["pending", "ongoing"],
        order_by: [asc: person.seq]
    end

    def with_contact_investigation_ongoing_interview() do
      from person in Person,
        join: contact_investigation in assoc(person, :contact_investigations),
        on: person.id == contact_investigation.exposed_person_id,
        where: contact_investigation.interview_status == "started",
        order_by: [asc: person.seq]
    end

    def with_contact_investigation_pending_interview() do
      from person in Person,
        join: contact_investigation in assoc(person, :contact_investigations),
        on: person.id == contact_investigation.exposed_person_id,
        where: contact_investigation.interview_status == "pending",
        order_by: [asc: person.seq]
    end
  end
end
