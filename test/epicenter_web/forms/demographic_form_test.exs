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
            "major" => ["Some other race", "asian", "black_or_african_american", "native_hawaiian_or_other_pacific_islander"],
            "detailed" => %{
              "asian" => ["Some other asian", "filipino", "korean"],
              "native_hawaiian_or_other_pacific_islander" => ["Some other pacific islander", "samoan"]
            }
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
          ethnicity: %{"detailed" => %{}, "major" => %{}},
          ethnicity_hispanic_latinx_or_spanish_origin: nil,
          gender_identity: %{"detailed" => %{}, "major" => %{}},
          marital_status: nil,
          notes: nil,
          occupation: nil,
          race: %{
            "major" => %{
              "values" => ["asian", "black_or_african_american", "native_hawaiian_or_other_pacific_islander"],
              "other" => "Some other race"
            },
            "detailed" => %{
              "asian" => %{"values" => ["filipino", "korean"], "other" => "Some other asian"},
              "native_hawaiian_or_other_pacific_islander" => %{"values" => ["samoan"], "other" => "Some other pacific islander"}
            }
          },
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
        "ethnicity" => %{
          "major" => %{"values" => ["hispanic_latinx_or_spanish_origin"]},
          "detailed" => %{"hispanic_latinx_or_spanish_origin" => %{"values" => ["puerto_rican"], "other" => "other ethnicity"}}
        },
        "gender_identity" => %{"major" => %{"values" => ["male"], "other" => "other gender identity"}},
        "marital_status" => ["married"],
        "notes" => "the notes",
        "occupation" => "the occupation",
        "race" => %{
          "major" => %{"values" => ["asian", "native_hawaiian_or_other_pacific_islander", "white"], "other" => "Other race"},
          "detailed" => %{
            "asian" => %{"values" => ["filipino", "japanese"], "other" => "Other asian"},
            "native_hawaiian_or_other_pacific_islander" => %{"values" => ["samoan"], "other" => "Other pacific islander"}
          }
        },
        "sex_at_birth" => ["female"]
      }
      |> DemographicForm.attrs_to_form_changeset()
      |> DemographicForm.form_changeset_to_model_attrs()
      |> assert_eq(
        {:ok,
         %{
           employment: "not_employed",
           ethnicity: %{"detailed" => ["other ethnicity", "puerto_rican"], "major" => "hispanic_latinx_or_spanish_origin"},
           gender_identity: ["male", "other gender identity"],
           marital_status: "married",
           notes: "the notes",
           occupation: "the occupation",
           race: %{
             "detailed" => %{
               "asian" => ["Other asian", "filipino", "japanese"],
               "native_hawaiian_or_other_pacific_islander" => ["Other pacific islander", "samoan"]
             },
             "major" => ["Other race", "asian", "native_hawaiian_or_other_pacific_islander", "white"]
           },
           sex_at_birth: "female",
           source: "form"
         }}
      )
    end
  end
end
