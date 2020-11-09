defmodule Epicenter.Cases.Demographic do
  use Ecto.Schema

  import Ecto.Changeset
  import Epicenter.PhiValidation, only: [validate_phi: 2]

  alias Epicenter.Cases.Person
  alias Epicenter.Cases.Ethnicity

  @required_attrs ~w{dob first_name last_name}a
  @optional_attrs ~w{external_id preferred_language tid employment gender_identity marital_status notes occupation person_id race sex_at_birth source}a
  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  # demographic field: a field over which someone would want analytics
  schema "demographics" do
    field :dob, :date
    field :employment, :string

    embeds_one :ethnicity, Ethnicity, on_replace: :delete

    field :external_id, :string
    field :first_name, :string
    field :gender_identity, {:array, :string}
    field :last_name, :string
    field :marital_status, :string
    field :notes, :string
    field :occupation, :string
    field :preferred_language, :string
    field :race, :string
    field :seq, :integer
    field :sex_at_birth, :string
    field :tid, :string
    field :source, :string

    timestamps(type: :utc_datetime)

    belongs_to :person, Person
  end

  def changeset(demographic, attrs) do
    demographic
    |> cast(Enum.into(attrs, %{}), @required_attrs ++ @optional_attrs)
    |> cast_embed(:ethnicity, with: &Ethnicity.changeset/2)
    |> validate_phi(:demographic)
  end

  def find_humanized_value(field, value) do
    case Map.get(humanized_values(), field) do
      nil ->
        value

      humanized_values_for_field ->
        default = {value, value}
        {humanized, _val} = Enum.find(humanized_values_for_field, default, fn {_humanized, val} -> val == value end)
        humanized
    end
  end

  def humanized_values do
    %{
      gender_identity: [
        {"Female", "female"},
        {"Transgender woman/trans woman/male-to-female (MTF)", "transgender_woman"},
        {"Male", "male"},
        {"Transgender man/trans man/female-to-male (FTM)", "transgender_man"},
        {"Genderqueer/gender nonconforming neither exclusively male nor female", "gender_nonconforming"}
      ],
      sex_at_birth: [
        {"Female", "female"},
        {"Male", "male"},
        {"Intersex", "intersex"}
      ],
      ethnicity: [
        {"Not Hispanic, Latino/a, or Spanish origin", "not_hispanic_latinx_or_spanish_origin"},
        {"Hispanic, Latino/a, or Spanish origin", "hispanic_latinx_or_spanish_origin"},
        {"Mexican, Mexican American, Chicano/a", "mexican_mexican_american_chicanx"},
        {"Puerto Rican", "puerto_rican"},
        {"Cuban", "cuban"}
      ],
      race: [
        {"White", "white"},
        {"Black or African American", "black_or_african_american"},
        {"American Indian or Alaska Native", "american_indian_or_alaska_native"},
        {"Asian", "asian"},
        {"Asian Indian", "asian_indian"},
        {"Chinese", "chinese"},
        {"Filipino", "filipino"},
        {"Japanese", "japanese"},
        {"Korean", "korean"},
        {"Vietnamese", "vietnamese"},
        {"Native Hawaiian or Other Pacific Islander", "native_hawaiian_or_other_pacific_islander"},
        {"Native Hawaiian", "native_hawaiian"},
        {"Guamanian or Chamorro", "guamanian_or_chamorro"},
        {"Samoan", "samoan"}
      ],
      marital_status: [
        {"Single", "single"},
        {"Married", "married"}
      ],
      employment: [
        {"Not employed", "not_employed"},
        {"Part time", "part_time"},
        {"Full time", "full_time"}
      ]
    }
  end

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
