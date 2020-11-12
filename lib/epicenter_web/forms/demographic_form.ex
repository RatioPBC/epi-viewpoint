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
        ~w{employment ethnicity gender_identity_other marital_status sex_at_birth},
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
        attrs =
          form
          |> Map.from_struct()
          |> Map.put(:source, "form")
          |> convert_ethnicity_fields_to_ethnicity()
          |> convert_gender_identity_fields()

        {:ok, attrs}

      other ->
        other
    end
  end

  defp convert_gender_identity_fields(map) do
    gender_identity = Map.get(map, :gender_identity)
    gender_identity_other = Map.get(map, :gender_identity_other)

    map
    |> Map.put(:gender_identity, List.wrap(gender_identity) ++ List.wrap(gender_identity_other))
    |> Map.delete(:gender_identity_other)
  end

  defp convert_ethnicity_fields_to_ethnicity(map) do
    case {map.ethnicity, map.ethnicity_hispanic_latinx_or_spanish_origin} do
      {"hispanic_latinx_or_spanish_origin" = major, detailed} ->
        map |> Map.put(:ethnicity, %{major: major, detailed: detailed})

      {major, _detailed} ->
        map |> Map.put(:ethnicity, %{major: major, detailed: nil})
    end
    |> Map.delete(:ethnicity_hispanic_latinx_or_spanish_origin)
  end
end
