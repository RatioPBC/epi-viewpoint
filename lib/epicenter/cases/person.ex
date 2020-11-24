defmodule Epicenter.Cases.Person do
  use Ecto.Schema

  import Ecto.Changeset
  alias Epicenter.Accounts.User
  alias Epicenter.Cases
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
    field :seq, :integer
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
    |> cast_assoc(:demographics, with: &Demographic.changeset/2)
    |> cast_assoc(:addresses, with: &Address.changeset/2)
    |> cast_assoc(:emails, with: &Email.changeset/2)
    |> cast_assoc(:phones, with: &Phone.changeset/2)
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
    |> Cases.preload_lab_results()
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
      from [_person, case_investigation] in person_with_case_investigation(),
        where: not is_nil(case_investigation.completed_interview_at) and is_nil(case_investigation.isolation_concluded_at)
    end

    def with_ongoing_interview() do
      from [_person, case_investigation] in person_with_case_investigation(),
        where:
          not is_nil(case_investigation.started_at) and is_nil(case_investigation.completed_interview_at) and
            is_nil(case_investigation.discontinued_at)
    end

    def with_pending_interview() do
      from [_person, case_investigation] in person_with_case_investigation(),
        where:
          is_nil(case_investigation.started_at) and is_nil(case_investigation.completed_interview_at) and is_nil(case_investigation.discontinued_at)
    end

    def with_positive_lab_results() do
      from person in Person,
        inner_join: lab_result in subquery(newest_positive_lab_result()),
        on: lab_result.person_id == person.id,
        order_by: [asc: lab_result.max_sampled_on, asc: person.seq]
    end

    defp newest_positive_lab_result() do
      from lab_result in LabResult,
        select: %{
          person_id: lab_result.person_id,
          max_sampled_on: max(lab_result.sampled_on)
        },
        where: ilike(lab_result.result, "positive"),
        or_where: ilike(lab_result.result, "detected"),
        group_by: lab_result.person_id
    end

    defp person_with_case_investigation() do
      from person in Person,
        join: case_investigation in CaseInvestigation,
        on: case_investigation.person_id == person.id,
        distinct: [desc: case_investigation.inserted_at, desc: case_investigation.seq, desc: person.seq, desc: person.id]
    end
  end
end
