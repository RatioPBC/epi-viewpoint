defmodule EpicenterWeb.Forms.DemographicForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Ethnicity
  alias Epicenter.Coerce
  alias EpicenterWeb.Forms.DemographicForm

  @primary_key false

  embedded_schema do
    field :employment, :string

    field :ethnicity, :string
    field :ethnicity_hispanic_latinx_or_spanish_origin, {:array, :string}
    field :ethnicity_hispanic_latinx_or_spanish_origin_other, :string

    field :gender_identity, {:array, :string}
    field :gender_identity_other, :string

    field :marital_status, :string
    field :notes, :string
    field :occupation, :string

    field :race, :string
    field :race_asian, {:array, :string}
    field :race_asian_other, :string
    field :race_native_hawaiian_or_other_pacific_islander, {:array, :string}
    field :race_native_hawaiian_or_other_pacific_islander_other, :string

    field :sex_at_birth, :string
  end

  @required_attrs ~w{}a
  @optional_attrs ~w{
    employment
    ethnicity
    ethnicity_hispanic_latinx_or_spanish_origin
    ethnicity_hispanic_latinx_or_spanish_origin_other
    gender_identity
    gender_identity_other
    marital_status
    notes
    occupation
    race
    race_asian
    race_native_hawaiian_or_other_pacific_islander
    sex_at_birth
  }a

  def model_to_form_changeset(%Demographic{} = demographic) do
    demographic |> model_to_form_attrs() |> attrs_to_form_changeset()
  end

  def model_to_form_attrs(%Demographic{} = demographic) do
    {gender_identity, gender_identity_other} =
      (demographic.gender_identity || []) |> Enum.split_with(&(&1 in Demographic.standard_values(:gender_identity)))

    %{
      employment: demographic.employment,
      ethnicity: demographic.ethnicity |> Ethnicity.major(),
      ethnicity_hispanic_latinx_or_spanish_origin: demographic.ethnicity |> Ethnicity.hispanic_latinx_or_spanish_origin(),
      gender_identity: gender_identity,
      gender_identity_other: gender_identity_other,
      marital_status: demographic.marital_status,
      notes: demographic.notes,
      occupation: demographic.occupation,
      race: demographic.race,
      race_asian: [],
      race_native_hawaiian_or_other_pacific_islander: [],
      sex_at_birth: demographic.sex_at_birth
    }
  end

  def attrs_to_form_changeset(attrs) do
    attrs =
      attrs
      |> Euclid.Extra.Map.stringify_keys()
      |> Euclid.Extra.Map.transform(
        ~w{employment ethnicity ethnicity_hispanic_latinx_or_spanish_origin_other gender_identity_other marital_status sex_at_birth},
        &Coerce.to_string_or_nil/1
      )

    # race should eventually be a list but that requires a db change
    attrs =
      attrs
      |> Euclid.Extra.Map.transform("race", fn
        s when is_binary(s) -> s
        list when is_list(list) -> List.first(list)
        nil -> nil
      end)

    %DemographicForm{}
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def form_changeset_to_model_attrs(%Ecto.Changeset{} = form_changeset) do
    case apply_action(form_changeset, :create) do
      {:ok, form} ->
        {:ok,
         %{
           employment: form.employment,
           ethnicity: extract_ethnicity(form),
           gender_identity: extract_gender_identity(form),
           marital_status: form.marital_status,
           notes: form.notes,
           occupation: form.occupation,
           race: form.race,
           sex_at_birth: form.sex_at_birth,
           source: "form"
         }}

      other ->
        other
    end
  end

  defp extract_ethnicity(form) do
    major = form.ethnicity

    detailed =
      if major == "hispanic_latinx_or_spanish_origin" do
        [form.ethnicity_hispanic_latinx_or_spanish_origin, form.ethnicity_hispanic_latinx_or_spanish_origin_other]
        |> flat_compact()
      else
        nil
      end

    %{major: major, detailed: detailed}
  end

  defp extract_gender_identity(form) do
    [form.gender_identity, form.gender_identity_other] |> flat_compact()
  end

  defp flat_compact(list) do
    list |> List.flatten() |> Enum.filter(&Euclid.Exists.present?/1)
  end
end
