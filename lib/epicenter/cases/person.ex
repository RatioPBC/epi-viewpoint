defmodule Epicenter.Cases.Person do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.Validation, only: [validate_phi: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Extra

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "people" do
    field :dob, :date
    field :fingerprint, :string
    field :first_name, :string
    field :last_name, :string
    field :originator, :map, virtual: true
    field :seq, :integer
    field :tid, :string

    timestamps()

    has_many :lab_results, LabResult
  end

  @required_attrs ~w{dob first_name last_name originator}a
  @optional_attrs ~w{tid}a

  def changeset(person, attrs) do
    person
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> validate_phi()
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
      lab_results -> lab_results |> Enum.max_by(& &1.sample_date, Date)
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

    def call_list() do
      fifteen_days_ago = Extra.Date.days_ago(15)

      from person in all(),
        join: lab_result in assoc(person, :lab_results),
        where: lab_result.result == "positive",
        where: lab_result.sample_date > ^fifteen_days_ago
    end

    def opts_for_upsert() do
      [returning: true, on_conflict: {:replace_all_except, ~w{id dob fingerprint first_name last_name}a}, conflict_target: :fingerprint]
    end
  end
end
