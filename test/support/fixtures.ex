defmodule Epicenter.Test.Fixtures do
  alias Epicenter.AuditLog
  alias Epicenter.Accounts.User
  alias Epicenter.Cases.CaseInvestigation
  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.DateParser

  def audit_meta(author) do
    %AuditLog.Meta{
      author_id: author.id,
      reason_action: "test-run",
      reason_event: "test"
    }
  end

  @admin_id Ecto.UUID.generate()
  def admin(),
    do: %Epicenter.Accounts.User{
      id: @admin_id,
      tid: "admin",
      admin: true,
      name: "fixture admin",
      email: "admin@example.com",
      hashed_password: "adminpassword",
      mfa_secret: "123456",
      confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

  def admin_audit_meta(), do: audit_meta(admin())

  def lab_result_attrs(%Person{id: person_id}, author, tid, sampled_on, attrs \\ %{}) do
    attrs =
      %{
        person_id: person_id,
        request_accession_number: "accession-" <> tid,
        request_facility_code: "facility-" <> tid,
        request_facility_name: tid <> " Lab, Inc.",
        result: "positive",
        sampled_on: sampled_on |> DateParser.parse_mm_dd_yyyy!(),
        tid: tid
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(author)}
  end

  def case_investigation_attrs(%Person{id: person_id}, %LabResult{id: initiating_lab_result_id}, author, tid, attrs \\ %{}) do
    attrs =
      %{
        initiating_lab_result_id: initiating_lab_result_id,
        person_id: person_id,
        interview_started_at: nil,
        tid: tid
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(author)}
  end

  def case_investigation_note_attrs(%CaseInvestigation{id: case_investigation_id}, %User{id: author_id} = author, tid, attrs) do
    attrs =
      %{
        author_id: author_id,
        case_investigation_id: case_investigation_id,
        tid: tid
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(author)}
  end

  def contact_investigation_attrs(tid, attrs \\ %{}) do
    %{
      tid: tid,
      relationship_to_case: "Family",
      most_recent_date_together: ~D[2020-10-31],
      household_member: false,
      exposed_person: %{
        demographics: [
          %{
            source: "form",
            first_name: "Caroline",
            last_name: "Testuser",
            preferred_language: "Haitian Creole"
          }
        ],
        phones: [
          %{
            number: "1111111543"
          }
        ],
        tid: "exposed_person_#{tid}"
      },
      under_18: false
    }
    |> merge_attrs(attrs)
  end

  # annotated with audit_meta
  @doc "opts - :demographics (boolean)"
  def person_attrs(originator, tid, attrs \\ %{}, opts \\ []) do
    new_attrs = raw_person_attrs(tid, attrs)
    new_attrs = if Keyword.get(opts, :demographics, true), do: add_demographic_attrs(new_attrs), else: new_attrs
    new_attrs = new_attrs |> merge_attrs(attrs)
    {new_attrs, audit_meta(originator)}
  end

  def raw_person_attrs(tid, attrs \\ %{}) do
    %{
      tid: tid
    }
    |> merge_attrs(attrs)
  end

  def add_demographic_attrs(attrs_or_attrs_with_audit_tuple, demographic_attrs \\ %{})

  def add_demographic_attrs({person_attrs, audit_meta}, demographic_attrs),
    do: {add_demographic_attrs(person_attrs, demographic_attrs), audit_meta}

  def add_demographic_attrs(%{demographics: [person_demographic_attrs]} = person_attrs, demographic_attrs) do
    merged_demographic_attrs =
      %{
        dob: ~D[2000-01-01],
        employment: "part_time",
        ethnicity: %{major: "not_hispanic_latinx_or_spanish_origin", detailed: []},
        first_name: String.capitalize(person_attrs.tid),
        gender_identity: ["female"],
        last_name: "Testuser",
        marital_status: "single",
        notes: "lorem ipsum",
        occupation: "architect",
        preferred_language: "English",
        race: %{major: ["asian"], detailed: %{asian: ["filipino"]}},
        sex_at_birth: "female"
      }
      |> merge_attrs(person_demographic_attrs)
      |> merge_attrs(demographic_attrs)

    %{person_attrs | demographics: [merged_demographic_attrs]}
  end

  def add_demographic_attrs(person_attrs, demographic_attrs) do
    add_demographic_attrs(Map.put(person_attrs, :demographics, [%{}]), demographic_attrs)
  end

  def add_empty_demographic_attrs(person_attrs) do
    add_demographic_attrs(person_attrs, %{
      "employment" => nil,
      "ethnicity" => nil,
      "gender_identity" => nil,
      "marital_status" => nil,
      "notes" => nil,
      "occupation" => nil,
      "race" => nil,
      "sex_at_birth" => nil
    })
  end

  def address_attrs(originator, %Person{id: person_id}, tid, street_number, attrs \\ %{}) when is_binary(tid) and is_integer(street_number) do
    attrs =
      %{
        city: "City",
        person_id: person_id,
        postal_code: "00000",
        state: "OH",
        street: "#{street_number} Test St",
        tid: tid,
        type: "home"
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(originator)}
  end

  def demographic_attrs(author, person, tid, attrs \\ %{}) do
    attrs =
      %{
        dob: ~D[2000-01-01],
        first_name: tid,
        last_name: "Testuser",
        person_id: person.id,
        tid: tid
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(author)}
  end

  def phone_attrs(author, %Person{id: person_id}, tid, attrs \\ %{}) do
    attrs =
      %{
        number: "111-111-1000",
        person_id: person_id,
        tid: tid,
        type: "home"
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(author)}
  end

  def email_attrs(author, %Person{id: person_id}, tid, attrs \\ %{}) do
    attrs =
      %{
        address: "#{tid}@example.com",
        person_id: person_id,
        tid: tid
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(author)}
  end

  def user_attrs(author, %{tid: tid} = attrs),
    do: user_attrs(author, tid, Map.delete(attrs, :tid))

  def user_attrs(author, tid, attrs \\ %{}) do
    attrs =
      %{
        email: tid <> "@example.com",
        name: tid,
        password: "password123",
        tid: tid
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(author)}
  end

  def imported_file_attrs(author, tid, attrs \\ %{}) do
    attrs =
      %{
        file_name: "test_results_september_14_2020",
        tid: tid
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(author)}
  end

  def revision_attrs(tid, attrs \\ %{}) do
    %{
      author_id: "author",
      changed_type: "Epicenter.Cases.Person",
      reason_action: "reason_action",
      reason_event: "reason_event",
      tid: tid
    }
    |> merge_attrs(attrs)
  end

  defp merge_attrs(defaults, attrs) do
    Map.merge(defaults, Enum.into(attrs, %{}))
  end

  def wrap_with_audit_meta(thing) do
    {thing, admin_audit_meta()}
  end
end
