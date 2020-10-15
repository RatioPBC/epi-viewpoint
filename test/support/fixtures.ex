defmodule Epicenter.Test.Fixtures do
  alias Epicenter.AuditLog
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
  def admin(), do: %Epicenter.Accounts.User{id: @admin_id, tid: "admin"}
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

  # annotated with audit_meta
  def person_attrs(originator, tid, attrs \\ %{}) do
    attrs =
      raw_person_attrs(originator, tid, attrs)
      |> merge_attrs(attrs)

    {attrs, audit_meta(originator)}
  end

  def raw_person_attrs(originator, tid, attrs \\ %{}) do
    %{
      dob: ~D[2000-01-01],
      first_name: String.capitalize(tid),
      last_name: "Testuser",
      originator: originator,
      preferred_language: "English",
      tid: tid
    }
    |> merge_attrs(attrs)
  end

  def add_demographic_attrs(attrs_or_attrs_with_audit_tuple, demographic_attrs \\ %{})

  def add_demographic_attrs({person_attrs, audit_meta}, demographic_attrs),
    do: {add_demographic_attrs(person_attrs, demographic_attrs), audit_meta}

  def add_demographic_attrs(person_attrs, demographic_attrs) do
    %{
      employment: "Part time",
      ethnicity: %{major: "not_hispanic_latinx_or_spanish_origin", detailed: []},
      gender_identity: "Female",
      marital_status: "Single",
      notes: "lorem ipsum",
      occupation: "architect",
      race: "Filipino",
      sex_at_birth: "Female"
    }
    |> merge_attrs(demographic_attrs)
    |> merge_attrs(person_attrs)
  end

  def add_empty_demographic_attrs(person_attrs) do
    %{
      "employment" => nil,
      "ethnicity" => nil,
      "gender_identity" => nil,
      "marital_status" => nil,
      "notes" => nil,
      "occupation" => nil,
      "race" => nil,
      "sex_at_birth" => nil
    }
    |> merge_attrs(person_attrs)
  end

  def address_attrs(originator, %Person{id: person_id}, tid, street_number, attrs \\ %{}) when is_binary(tid) and is_integer(street_number) do
    attrs =
      %{
        street: "#{street_number} Test St",
        city: "City",
        state: "TS",
        postal_code: "00000",
        type: "home",
        person_id: person_id,
        tid: tid
      }
      |> merge_attrs(attrs)

    {attrs, audit_meta(originator)}
  end

  def phone_attrs(author, %Person{id: person_id}, tid, attrs \\ %{}) do
    attrs =
      %{
        number: "111-111-1000",
        person_id: person_id,
        type: "home",
        tid: tid
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
end
