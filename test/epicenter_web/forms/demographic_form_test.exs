defmodule EpicenterWeb.Forms.DemographicFormTest do
  use Epicenter.SimpleCase, async: true

  alias EpicenterWeb.Forms.DemographicForm

  describe "converting form attrs to model attrs" do
    test "all fields" do
      %{
        "employment" => ["not_employed"],
        "ethnicity" => ["hispanic_latinx_or_spanish_origin"],
        "ethnicity_hispanic_latinx_or_spanish_origin" => ["puerto_rican"],
        "ethnicity_hispanic_latinx_or_spanish_origin_other" => "other ethnicity",
        "gender_identity" => ["male"],
        "gender_identity_other" => "other gender identity",
        "marital_status" => ["married"],
        "notes" => "the notes",
        "occupation" => "the occupation",
        "race" => ["asian"],
        "race_asian_other" => "",
        "race_native_hawaiian_or_other_pacific_islander_other" => "",
        "race_other" => "",
        "sex_at_birth" => ["female"]
      }
      |> DemographicForm.attrs_to_form_changeset()
      |> DemographicForm.form_changeset_to_model_attrs()
      |> assert_eq(
        {:ok,
         %{
           employment: "not_employed",
           ethnicity: %{detailed: ["puerto_rican", "other ethnicity"], major: "hispanic_latinx_or_spanish_origin"},
           gender_identity: ["male", "other gender identity"],
           marital_status: "married",
           notes: "the notes",
           occupation: "the occupation",
           race: "asian",
           sex_at_birth: "female",
           source: "form"
         }}
      )
    end
  end
end
