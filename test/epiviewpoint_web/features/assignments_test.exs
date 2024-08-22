defmodule EpiViewpointWeb.Features.AssignmentsTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Extra
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

  setup :register_and_log_in_user

  @admin Test.Fixtures.admin()

  test "people can be assigned to users on people and profile page", %{conn: conn, user: user} do
    assignee = Test.Fixtures.user_attrs(@admin, "assignee") |> Accounts.register_user!()
    Test.Fixtures.user_attrs(@admin, "nonassignee") |> Accounts.register_user!()

    alice = Test.Fixtures.person_attrs(assignee, "alice") |> Cases.create_person!()

    alice_lab_result =
      Test.Fixtures.lab_result_attrs(alice, @admin, "alice-result-1", Extra.Date.days_ago(1), result: "positive") |> Cases.create_lab_result!()

    Test.Fixtures.case_investigation_attrs(alice, alice_lab_result, user, "") |> Cases.create_case_investigation!()

    billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()

    billy_lab_result =
      Test.Fixtures.lab_result_attrs(billy, @admin, "billy-result-1", Extra.Date.days_ago(2), result: "positive") |> Cases.create_lab_result!()

    Test.Fixtures.case_investigation_attrs(billy, billy_lab_result, user, "") |> Cases.create_case_investigation!()
    #
    # nobody is assigned
    #

    Pages.People.visit(conn) |> Pages.People.assert_assignees(%{"Alice Testuser" => "", "Billy Testuser" => ""})
    Pages.Profile.visit(conn, alice) |> Pages.Profile.assert_assigned_user("Unassigned")
    Test.Cases.assert_assignees(%{alice => nil, billy => nil})

    #
    # assign "assignee" from the profile page
    #

    Pages.Profile.visit(conn, alice)
    |> Pages.Profile.assert_assignable_users(["Unassigned", "assignee", "fixture admin", "nonassignee", "user"])
    |> Pages.Profile.assign(assignee)

    #
    # "assignee" is assigned to alice
    #

    Pages.Profile.visit(conn, alice) |> Pages.Profile.assert_assigned_user("assignee")
    Pages.People.visit(conn) |> Pages.People.assert_assignees(%{"Alice Testuser" => "assignee", "Billy Testuser" => ""})

    Test.Cases.assert_assignees(%{alice => "assignee", billy => nil})

    #
    # unassign "assignee" from the profile page
    #

    Pages.Profile.visit(conn, alice) |> Pages.Profile.unassign()

    #
    # nobody is assigned
    #

    Pages.People.visit(conn) |> Pages.People.assert_assignees(%{"Alice Testuser" => "", "Billy Testuser" => ""})
    Pages.Profile.visit(conn, alice) |> Pages.Profile.assert_assigned_user("Unassigned")
    Test.Cases.assert_assignees(%{alice => nil, billy => nil})

    #
    # assign "assignee" to alice and billy from the people page
    #

    Pages.People.visit(conn) |> Pages.People.assign([alice, billy], assignee)

    #
    # "assignee" is assigned to alice and billy
    #

    Pages.People.visit(conn) |> Pages.People.assert_assignees(%{"Alice Testuser" => "assignee", "Billy Testuser" => "assignee"})
    Pages.Profile.visit(conn, alice) |> Pages.Profile.assert_assigned_user("assignee")
    Test.Cases.assert_assignees(%{alice => "assignee", billy => "assignee"})
  end
end
