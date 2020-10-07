defmodule EpicenterWeb.Features.AssignmentsTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  test "people can be assigned to users on people and profile page, with cross-client updating", %{conn: conn} do
    assignee = Test.Fixtures.user_attrs(%{id: "superuser"}, "assignee") |> Accounts.register_user!()
    Test.Fixtures.user_attrs(%{id: "superuser"}, "nonassignee") |> Accounts.register_user!()

    alice = Test.Fixtures.person_attrs(assignee, "alice") |> Cases.create_person!()
    billy = Test.Fixtures.person_attrs(assignee, "billy") |> Cases.create_person!()

    people_page = Pages.People.visit(conn)
    profile_page = Pages.Profile.visit(conn, alice)

    #
    # nobody is assigned
    #

    people_page |> Pages.People.assert_assignees(%{"Alice Testuser" => "", "Billy Testuser" => ""})
    profile_page |> Pages.Profile.assert_assigned_user("Unassigned")
    Test.Cases.assert_assignees(%{alice => nil, billy => nil})

    #
    # assign "assignee" from the profile page
    #

    profile_page
    |> Pages.Profile.assert_assignable_users(~w{Unassigned assignee nonassignee user})
    |> Pages.Profile.assign(assignee)

    #
    # "assignee" is assigned to alice
    #

    people_page |> Pages.People.assert_assignees(%{"Alice Testuser" => "assignee", "Billy Testuser" => ""})
    profile_page |> Pages.Profile.assert_assigned_user("assignee")
    Test.Cases.assert_assignees(%{alice => "assignee", billy => nil})

    #
    # unassign "assignee" from the profile page
    #

    profile_page |> Pages.Profile.unassign()

    #
    # nobody is assigned
    #

    people_page |> Pages.People.assert_assignees(%{"Alice Testuser" => "", "Billy Testuser" => ""})
    profile_page |> Pages.Profile.assert_assigned_user("Unassigned")
    Test.Cases.assert_assignees(%{alice => nil, billy => nil})

    #
    # assign "assignee" to alice and billy from the people page
    #

    people_page |> Pages.People.assign([alice, billy], assignee)

    #
    # "assignee" is assigned to alice and billy
    #

    people_page |> Pages.People.assert_assignees(%{"Alice Testuser" => "assignee", "Billy Testuser" => "assignee"})
    profile_page |> Pages.Profile.assert_assigned_user("assignee")
    Test.Cases.assert_assignees(%{alice => "assignee", billy => "assignee"})
  end
end
