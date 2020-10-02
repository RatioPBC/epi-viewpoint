defmodule Epicenter.Cases.Person do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.Validation, only: [validate_phi: 2]

  alias Epicenter.Accounts.User
  alias Epicenter.Cases
  alias Epicenter.Cases.Address
  alias Epicenter.Cases.Email
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Phone
  alias Epicenter.Extra

  @required_attrs ~w{dob first_name last_name}a
  @optional_attrs ~w{assigned_to_id external_id preferred_language tid employment ethnicity gender_identity marital_status notes occupation race sex_at_birth}a

  @derive {Jason.Encoder, only: @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "people" do
    field :dob, :date
    field :employment, :string
    field :ethnicity, :string
    field :external_id, :string
    field :fingerprint, :string
    field :first_name, :string
    field :gender_identity, :string
    field :last_name, :string
    field :marital_status, :string
    field :notes, :string
    field :occupation, :string
    field :originator, :map, virtual: true
    field :preferred_language, :string
    field :race, :string
    field :seq, :integer
    field :sex_at_birth, :string
    field :tid, :string

    timestamps()

    belongs_to :assigned_to, User
    has_many :addresses, Address
    has_many :emails, Email, on_replace: :delete
    has_many :lab_results, LabResult
    has_many :phones, Phone
  end

  def assignment_changeset(person, nil = _user), do: person |> changeset(%{assigned_to_id: nil})
  def assignment_changeset(person, %User{} = user), do: person |> changeset(%{assigned_to_id: user.id})

  def changeset(person, attrs) do
    person
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> cast_assoc(:emails, with: &Email.changeset/2)
    |> cast_assoc(:phones, with: &Phone.changeset/2)
    |> validate_required(@required_attrs)
    |> validate_phi(:person)
    |> change_fingerprint()
    |> unique_constraint(:fingerprint)
  end

  defp change_fingerprint(%Ecto.Changeset{valid?: true} = changeset) do
    dob = changeset |> get_field(:dob) |> Date.to_iso8601()
    first_name = changeset |> get_field(:first_name) |> String.downcase()
    last_name = changeset |> get_field(:last_name) |> String.downcase()

    changeset |> change(fingerprint: "#{dob} #{first_name} #{last_name}")
  end

  defp change_fingerprint(changeset), do: changeset

  def latest_lab_result(person) do
    case person |> Cases.preload_lab_results() |> Map.get(:lab_results) do
      nil -> nil
      [] -> nil
      lab_results -> lab_results |> Enum.max_by(& &1.sampled_on, Date)
    end
  end

  def latest_lab_result(person, field) do
    case latest_lab_result(person) do
      nil -> nil
      lab_result -> Map.get(lab_result, field)
    end
  end

  defmodule Query do
    import Ecto.Query

    def all() do
      from person in Person,
        order_by: [asc: person.last_name, asc: person.first_name, desc: person.dob, asc: person.seq]
    end

    def get_people(ids) do
      from person in Person,
        where: person.id in ^ids,
        order_by: [asc: person.last_name, asc: person.first_name, desc: person.dob, asc: person.seq]
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

    @fields_to_not_be_replaced ~w{id dob ethnicity fingerprint first_name last_name occupation race sex_at_birth}a
    def opts_for_upsert() do
      [returning: true, on_conflict: {:replace_all_except, @fields_to_not_be_replaced}, conflict_target: :fingerprint]
    end
  end
end
