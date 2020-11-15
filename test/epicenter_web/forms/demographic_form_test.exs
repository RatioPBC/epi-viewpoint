defmodule EpicenterWeb.Forms.DemographicFormTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases.Demographic
  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias EpicenterWeb.Forms.DemographicForm

  describe "model_to_form_changeset" do
    setup :persist_admin

    setup do
      {attrs, _audit} =
        Test.Fixtures.demographic_attrs(%Person{id: "111"}, %Person{id: "222"}, "demographic", %{
          race: %{
            "black_or_african_american" => nil,
            "asian" => ["filipino", "korean", "Some other asian"],
            "native_hawaiian_or_other_pacific_islander" => ["samoan", "Some other pacific islander"],
            "Some other race" => nil
          }
        })

      [demographic: struct!(Demographic, attrs)]
    end

    test "all fields", %{demographic: demographic} do
      demographic
      |> DemographicForm.model_to_form_attrs()
      |> assert_eq(
        %{
          employment: nil,
          ethnicity: nil,
          ethnicity_hispanic_latinx_or_spanish_origin: nil,
          gender_identity: [],
          gender_identity_other: [],
          marital_status: nil,
          notes: nil,
          occupation: nil,
          race: [
            "asian",
            "black_or_african_american",
            "native_hawaiian_or_other_pacific_islander"
          ],
          race_asian: ["filipino", "korean"],
          race_asian_other: "Some other asian",
          race_native_hawaiian_or_other_pacific_islander: [
            "samoan"
          ],
          race_native_hawaiian_or_other_pacific_islander_other: "Some other pacific islander",
          race_other: "Some other race",
          sex_at_birth: nil
        },
        :simple
      )
    end
  end

  describe "form_changeset_to_model_attrs" do
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
        "race" => ["asian", "native_hawaiian_or_other_pacific_islander", "white"],
        "race_asian" => ["filipino", "japanese"],
        "race_asian_other" => "Other asian",
        "race_native_hawaiian_or_other_pacific_islander" => ["samoan"],
        "race_native_hawaiian_or_other_pacific_islander_other" => "Other pacific islander",
        "race_other" => "Other race",
        "sex_at_birth" => ["female"]
      }
      |> DemographicForm.attrs_to_form_changeset()
      |> DemographicForm.form_changeset_to_model_attrs()
      |> assert_eq(
        {:ok,
         %{
           employment: "not_employed",
           ethnicity: %{detailed: ["other ethnicity", "puerto_rican"], major: "hispanic_latinx_or_spanish_origin"},
           gender_identity: ["male", "other gender identity"],
           marital_status: "married",
           notes: "the notes",
           occupation: "the occupation",
           race: %{
             "asian" => ["Other asian", "filipino", "japanese"],
             "native_hawaiian_or_other_pacific_islander" => ["Other pacific islander", "samoan"],
             "Other race" => nil,
             "white" => nil
           },
           sex_at_birth: "female",
           source: "form"
         }}
      )
    end
  end
end
