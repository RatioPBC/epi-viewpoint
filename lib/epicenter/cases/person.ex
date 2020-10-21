defmodule Epicenter.Cases.Person do
  use Ecto.Schema

  import Ecto.Changeset
  alias Epicenter.Accounts.User
  alias Epicenter.Cases
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.Email
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Phone
  alias Epicenter.Extra
  alias Epicenter.Extra.Date.NilFirst

  @optional_attrs ~w{assigned_to_id tid}a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "people" do
    field :tid, :string

    timestamps(type: :utc_datetime)

    belongs_to :assigned_to, User
    has_many :demographics, Demographic
    has_many :addresses, Address
    has_many :emails, Email, on_replace: :delete
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

  def optional_attrs(), do: @optional_attrs

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

  def latest_lab_result(person) do
    person
    |> Cases.preload_lab_results()
    |> Map.get(:lab_results)
    |> Enum.sort_by(& &1.seq, :desc)
    |> Enum.max_by(& &1.sampled_on, Extra.Date.NilFirst, fn -> nil end)
  end

  def oldest_positive_lab_result(person) do
    person
    |> Cases.preload_lab_results()
    |> Map.get(:lab_results)
    |> Enum.filter(&LabResult.is_positive?(&1))
    |> Enum.sort_by(& &1.seq, :asc)
    |> Enum.min_by(& &1.reported_on, NilFirst, fn -> nil end)
  end

  def coalesce_demographics(person) do
    scores = %{"form" => 1, "import" => 0}

    Epicenter.Cases.Demographic.__schema__(:fields)
    |> Enum.reduce(%{}, fn field, data ->
      demographic =
        person.demographics
        |> Enum.filter(fn demo -> Map.get(demo, field) != nil end)
        |> Enum.sort_by(& &1.inserted_at)
        |> Enum.sort_by(& &1.inserted_at)
        |> Enum.sort_by(&Map.get(scores, &1.source, -1))
        |> Enum.at(0)

      case demographic do
        nil ->
          Map.put(data, field, nil)

        demographic ->
          Map.put(data, field, Map.get(demographic, field))
      end
    end)
  end

  defmodule Query do
    import Ecto.Query

    def all() do
      from person in Person,
        order_by: [asc: person.seq]
    end

    def get_people(ids) do
      from person in Person,
        where: person.id in ^ids,
        order_by: [asc: person.seq]
    end

    def with_lab_results() do
      from person in Person,
        left_join: lab_result in subquery(newest_lab_result()),
        on: lab_result.person_id == person.id,
        order_by: [asc: lab_result.max_sampled_on, asc: person.seq]
    end

    defp newest_lab_result() do
      from lab_result in LabResult,
        select: %{
          person_id: lab_result.person_id,
          max_sampled_on: max(lab_result.sampled_on)
        },
        group_by: lab_result.person_id
    end

    def call_list() do
      fifteen_days_ago = Extra.Date.days_ago(15)

      from person in all(),
        join: lab_result in assoc(person, :lab_results),
        where: lab_result.result == "positive",
        where: lab_result.sampled_on > ^fifteen_days_ago
    end

    @fields_to_replace_from_csv ~w{updated_at}a
    def opts_for_upsert() do
      [returning: true, on_conflict: {:replace, @fields_to_replace_from_csv}, conflict_target: :fingerprint]
    end
  end
end
