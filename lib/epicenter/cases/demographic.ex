defmodule Epicenter.Cases.Demographic do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.PhiValidation, only: [validate_phi: 2]

  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Ethnicity

  @required_attrs ~w{}a
  @optional_attrs ~w{
    dob
    external_id
    first_name
    last_name
    preferred_language
    tid
    employment
    gender_identity
    marital_status
    notes
    occupation
    person_id
    race
    sex_at_birth
    source
  }a
  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  # demographic field: a field over which someone would want analytics
  schema "demographics" do
    field :dob, :date
    field :employment, :string
    field :external_id, :string
    field :first_name, :string
    field :gender_identity, {:array, :string}
    field :last_name, :string
    field :marital_status, :string
    field :notes, :string
    field :occupation, :string
    field :preferred_language, :string
    field :race, :map
    field :seq, :integer, read_after_writes: true
    field :sex_at_birth, :string
    field :tid, :string
    field :source, :string

    timestamps(type: :utc_datetime)

    embeds_one :ethnicity, Ethnicity, on_replace: :delete
    belongs_to :person, Person
  end

  def changeset(demographic, attrs) do
    demographic
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> cast_embed(:ethnicity, with: &Ethnicity.changeset/2)
    |> validate_required(@required_attrs)
    |> validate_phi(:demographic)
  end

  def build_attrs(nil, _field),
    do: nil

  def build_attrs(value, :race) do
    case search_humanized(value, :race) do
      {_humanized, value, nil = _parent} ->
        %{value => nil}

      {_humanized, value, parent} ->
        %{parent => [value]}
    end
  end

  defp search_humanized(query, field) do
    default = {query, query, nil}

    case Map.get(humanized_values(), field) do
      nil ->
        default

      humanized_values_for_field ->
        Enum.find(humanized_values_for_field, default, fn {humanized, value, _parent} -> query in [value, humanized] end)
    end
  end

  def find_humanized_value(field, value) do
    {humanized, _value, _parent} = search_humanized(value, field)
    humanized
  end

  def standard_values(field),
    do: humanized_values() |> Map.get(field) |> Enum.map(fn {_humanized, value, _parent} -> value end)

  def reject_nonstandard_values(values, _field, false = _reject?),
    do: values

  def reject_nonstandard_values(values, field, true = _reject?),
    do: MapSet.intersection(MapSet.new(values), MapSet.new(standard_values(field))) |> MapSet.to_list()

  def reject_standard_values(values, field),
    do: MapSet.difference(MapSet.new(values), MapSet.new(standard_values(field))) |> MapSet.to_list()

  def humanized_values do
    %{
      employment: [
        {"Unknown", "unknown", nil},
        {"Not employed", "not_employed", nil},
        {"Part time", "part_time", nil},
        {"Full time", "full_time", nil}
      ],
      ethnicity: [
        {"Unknown", "unknown", nil},
        {"Declined to answer", "declined_to_answer", nil},
        {"Not Hispanic, Latino/a, or Spanish origin", "not_hispanic_latinx_or_spanish_origin", nil},
        {"Hispanic, Latino/a, or Spanish origin", "hispanic_latinx_or_spanish_origin", nil},
        {"Mexican, Mexican American, Chicano/a", "mexican_mexican_american_chicanx", nil},
        {"Puerto Rican", "puerto_rican", nil},
        {"Cuban", "cuban", nil}
      ],
      gender_identity: [
        {"Unknown", "unknown", nil},
        {"Declined to answer", "declined_to_answer", nil},
        {"Female", "female", nil},
        {"Transgender woman/trans woman/male-to-female (MTF)", "transgender_woman", nil},
        {"Male", "male", nil},
        {"Transgender man/trans man/female-to-male (FTM)", "transgender_man", nil},
        {"Genderqueer/gender nonconforming neither exclusively male nor female", "gender_nonconforming", nil}
      ],
      marital_status: [
        {"Unknown", "unknown", nil},
        {"Single", "single", nil},
        {"Married", "married", nil}
      ],
      race: [
        {"Unknown", "unknown", nil},
        {"Declined to answer", "declined_to_answer", nil},
        {"White", "white", nil},
        {"Black or African American", "black_or_african_american", nil},
        {"American Indian or Alaska Native", "american_indian_or_alaska_native", nil},
        {"Asian", "asian", nil},
        {"Asian Indian", "asian_indian", "asian"},
        {"Chinese", "chinese", "asian"},
        {"Filipino", "filipino", "asian"},
        {"Japanese", "japanese", "asian"},
        {"Korean", "korean", "asian"},
        {"Vietnamese", "vietnamese", "asian"},
        {"Native Hawaiian or Other Pacific Islander", "native_hawaiian_or_other_pacific_islander", nil},
        {"Native Hawaiian", "native_hawaiian", "native_hawaiian_or_other_pacific_islander"},
        {"Guamanian or Chamorro", "guamanian_or_chamorro", "native_hawaiian_or_other_pacific_islander"},
        {"Samoan", "samoan", "native_hawaiian_or_other_pacific_islander"}
      ],
      sex_at_birth: [
        {"Unknown", "unknown", nil},
        {"Declined to answer", "declined_to_answer", nil},
        {"Female", "female", nil},
        {"Male", "male", nil},
        {"Intersex", "intersex", nil}
      ]
    }
  end

  def humanized_values(field),
    do: Map.get(humanized_values(), field)

  defmodule Query do
    import Ecto.Query
    alias Epicenter.Cases.Demographic

    def display_order() do
      from demographics in Demographic, order_by: [asc: demographics.seq]
    end

    def latest_form_demographic(%Person{id: person_id}) do
      from demographics in Demographic,
        where: demographics.person_id == ^person_id,
        where: demographics.source == "form",
        order_by: [desc: demographics.updated_at, desc: demographics.seq],
        limit: 1
    end

    def matching(dob: dob, first_name: first_name, last_name: last_name) do
      from(d in Demographic, where: [dob: ^dob, first_name: ^first_name, last_name: ^last_name])
      |> first()
    end
  end
end
