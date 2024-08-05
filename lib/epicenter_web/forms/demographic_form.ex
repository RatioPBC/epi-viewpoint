defmodule EpicenterWeb.Forms.DemographicForm do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Ethnicity
  alias Epicenter.Coerce
  alias Epicenter.MajorDetailed
  alias EpicenterWeb.Forms.DemographicForm

  @primary_key false

  embedded_schema do
    field(:employment, :string)
    field(:ethnicity, :map)
    field(:gender_identity, :map)
    field(:marital_status, :string)
    field(:notes, :string)
    field(:occupation, :string)
    field(:race, :map)
    field(:sex_at_birth, :string)
  end

  @required_attrs ~w{}a
  @optional_attrs ~w{
    employment
    ethnicity
    gender_identity
    marital_status
    notes
    occupation
    race
    sex_at_birth
  }a

  def model_to_form_changeset(%Demographic{} = demographic) do
    demographic |> model_to_form_attrs() |> attrs_to_form_changeset()
  end

  def model_to_form_attrs(%Demographic{} = demographic) do
    %{
      employment: demographic.employment,
      ethnicity: demographic.ethnicity |> MajorDetailed.for_form(Demographic.standard_values(:ethnicity)),
      ethnicity_hispanic_latinx_or_spanish_origin: demographic.ethnicity |> Ethnicity.hispanic_latinx_or_spanish_origin(),
      gender_identity:
        demographic.gender_identity
        |> MajorDetailed.for_form(Demographic.standard_values(:gender_identity)),
      marital_status: demographic.marital_status,
      notes: demographic.notes,
      occupation: demographic.occupation,
      race: demographic.race |> MajorDetailed.for_form(Demographic.standard_values(:race)),
      sex_at_birth: demographic.sex_at_birth
    }
  end

  def attrs_to_form_changeset(attrs) do
    attrs =
      attrs
      |> Euclid.Extra.Map.stringify_keys()
      |> Euclid.Extra.Map.transform(
        ~w{employment marital_status sex_at_birth},
        &Coerce.to_string_or_nil/1
      )

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
           ethnicity: form.ethnicity |> MajorDetailed.for_model(:map) |> Ethnicity.from_major_detailed(),
           gender_identity: form.gender_identity |> MajorDetailed.for_model(:list),
           marital_status: form.marital_status,
           notes: form.notes,
           occupation: form.occupation,
           race: form.race |> MajorDetailed.for_model(:map),
           sex_at_birth: form.sex_at_birth,
           source: "form"
         }}

      other ->
        other
    end
  end
end
