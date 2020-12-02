defmodule Epicenter.Cases.Person do
  use Ecto.Schema

  import Ecto.Changeset
  alias Epicenter.Accounts.User
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.Email
  alias Epicenter.Cases.Exposure
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Phone
  alias Epicenter.Extra

  @optional_attrs ~w{assigned_to_id tid}a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "people" do
    field :seq, :integer, read_after_writes: true
    field :tid, :string

    timestamps(type: :utc_datetime)

    belongs_to :assigned_to, User
    has_many :demographics, Demographic
    has_many :addresses, Address
    has_many :case_investigations, CaseInvestigation
    has_many :emails, Email, on_replace: :delete
    has_many :exposures, Exposure, on_replace: :delete, foreign_key: :exposed_person_id
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
    scores = %{"form" => 0, "import" => 1}

    Epicenter.Cases.Demographic.__schema__(:fields)
    |> Enum.reduce(%{}, fn field, data ->
      demographic =
        person.demographics
        |> Enum.filter(fn demo -> Map.get(demo, field) != nil end)
        |> Enum.sort_by(& &1.inserted_at, {:asc, NaiveDateTime})
        |> Enum.sort_by(&Map.get(scores, &1.source, 2))
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

  def latest_lab_result(person) do
    person
    |> Map.get(:lab_results)
    |> Enum.sort_by(& &1.seq, :desc)
    |> Enum.max_by(& &1.sampled_on, Extra.Date.NilFirst, fn -> nil end)
  end

  def optional_attrs(), do: @optional_attrs

  defmodule Query do
    import Ecto.Query

    def all(), do: from(person in Person, order_by: [asc: person.seq])

    def all_exposed() do
      from person in Person,
        join: exposure in assoc(person, :exposures),
        on: person.id == exposure.exposed_person_id,
        order_by: [asc: person.seq]
    end

    def assigned_to_id(query, user_id), do: query |> where([p], p.assigned_to_id == ^user_id)

    def filter(:all), do: Person.Query.all()
    def filter(:with_isolation_monitoring), do: Person.Query.with_isolation_monitoring()
    def filter(:with_ongoing_interview), do: Person.Query.with_ongoing_interview()
    def filter(:with_pending_interview), do: Person.Query.with_pending_interview()
    def filter(:with_positive_lab_results), do: Person.Query.with_positive_lab_results()

    def get_people(ids), do: from(person in Person, where: person.id in ^ids, order_by: [asc: person.seq])

    @fields_to_replace_from_csv ~w{updated_at}a
    def opts_for_upsert(), do: [returning: true, on_conflict: {:replace, @fields_to_replace_from_csv}, conflict_target: :fingerprint]

    def with_demographic_field(query, field, value), do: query |> join(:inner, [p], d in assoc(p, :demographics), on: field(d, ^field) == ^value)

    def with_isolation_monitoring() do
      case_investigations_in_isolation_monitoring =
        from case_investigation in CaseInvestigation,
          distinct: [desc: parent_as(:person).id],
          where:
            parent_as(:person).id == case_investigation.person_id and case_investigation.interview_status == "completed" and
              case_investigation.isolation_monitoring_status in ["pending", "ongoing"],
          order_by: [desc: parent_as(:person).id, desc: case_investigation.inserted_at, desc: case_investigation.seq]

      from person in Person,
        as: :person,
        inner_lateral_join: case_investigation in subquery(case_investigations_in_isolation_monitoring),
        order_by: [
          desc: case_investigation.isolation_monitoring_status,
          asc: case_investigation.isolation_monitoring_ended_on,
          desc: case_investigation.interview_completed_at,
          desc: person.seq
        ]
    end

    def with_ongoing_interview(), do: sorted_people_with_case_investigation_interview_status("started")
    def with_pending_interview(), do: sorted_people_with_case_investigation_interview_status("pending")

    defp sorted_people_with_case_investigation_interview_status(interview_status) do
      person_latest_positive_lab_results_most_recently_sampled_on =
        from lab_result in LabResult,
          where: lab_result.is_positive_or_detected == true,
          distinct: [desc: lab_result.person_id],
          order_by: [desc: lab_result.person_id, desc: lab_result.sampled_on]

      from person in Person,
        join: case_investigation in CaseInvestigation,
        on: case_investigation.person_id == person.id,
        left_join: assignee in User,
        on: assignee.id == person.assigned_to_id,
        join: lab_result in subquery(person_latest_positive_lab_results_most_recently_sampled_on),
        on: lab_result.person_id == person.id,
        where: case_investigation.interview_status == ^interview_status,
        order_by: [asc_nulls_first: assignee.name, desc: lab_result.sampled_on]
    end

    def with_positive_lab_results() do
      newest_positive_lab_result =
        from lab_result in LabResult,
          select: %{
            person_id: lab_result.person_id,
            max_sampled_on: max(lab_result.sampled_on)
          },
          where: lab_result.is_positive_or_detected == true,
          group_by: lab_result.person_id

      from person in Person,
        inner_join: lab_result in subquery(newest_positive_lab_result),
        on: lab_result.person_id == person.id,
        order_by: [asc: lab_result.max_sampled_on, asc: person.seq]
    end
  end
end
