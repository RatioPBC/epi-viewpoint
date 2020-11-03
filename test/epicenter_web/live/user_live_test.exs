defmodule EpicenterWeb.UserLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Epicenter.Accounts
  alias Epicenter.Accounts.UserToken
  alias EpicenterWeb.Test.Pages

  @admin Test.Fixtures.admin()

  setup :log_in_admin

  describe "user creation form" do
    test "allows admins to add admins", %{conn: conn} do
      Pages.User.visit(conn)
      |> Pages.submit_live("#user-form",
        user_form: %{"name" => "New User", "email" => "newadmin@example.com", "type" => "admin", "status" => "active"}
      )

      assert %{name: "New User", email: "newadmin@example.com", admin: true} = Accounts.get_user(email: "newadmin@example.com")
    end

    test "allows admins to add disabled users", %{conn: conn} do
      Pages.User.visit(conn)
      |> Pages.submit_live("#user-form",
        user_form: %{"name" => "New User", "email" => "newadmin@example.com", "type" => "member", "status" => "inactive"}
      )

      assert %{name: "New User", email: "newadmin@example.com", disabled: true} = Accounts.get_user(email: "newadmin@example.com")
    end

    test "includes the password reset link in the flash for a newly created user", %{conn: conn} do
      flash_content =
        Pages.User.visit(conn)
        |> Pages.submit_and_follow_redirect(conn, "#user-form",
          user_form: %{"name" => "New User", "email" => "newadmin@example.com", "type" => "admin", "status" => "active"}
        )
        |> Pages.Users.assert_here()
        |> Pages.Users.password_reset_text()

      captures =
        Regex.named_captures(~r[Reset link for newadmin@example.com: http://\w+:\d+/users/reset-password/(?<encoded_token>.+)], flash_content)

      {:ok, token} = Base.url_decode64(captures["encoded_token"], padding: false)

      assert user_token = Epicenter.Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.sent_to == "newadmin@example.com"
      assert user_token.context == "reset_password"
    end

    test "disallows users to create users with invalid email addresses", %{conn: conn} do
      view =
        Pages.User.visit(conn)
        |> Pages.submit_live("#user-form",
          user_form: %{"name" => "New User", "email" => "an invalid email address", "type" => "member", "status" => "active"}
        )

      assert_validation_messages(render(view), %{"user_form_email" => "must have the @ sign and no spaces"})
    end

    test "all fields are required", %{conn: conn} do
      view =
        Pages.User.visit(conn)
        |> Pages.submit_live("#user-form",
          user_form: %{"name" => "", "email" => "", "type" => "member", "status" => "active"}
        )

      assert_validation_messages(render(view), %{"user_form_email" => "can't be blank", "user_form_name" => "can't be blank"})
    end

    test "must have unique emails", %{conn: conn} do
      view =
        Pages.User.visit(conn)
        |> Pages.submit_live("#user-form",
          user_form: %{"name" => "real name", "email" => @admin.email, "type" => "member", "status" => "active"}
        )
        |> Pages.User.assert_here()

      assert_validation_messages(render(view), %{"user_form_email" => "has already been taken"})
    end
  end

  describe "user update form" do
    test "is prefilled properly", %{conn: conn} do
      subject_user = Epicenter.AccountsFixtures.user_fixture(%{tid: "existinguser", name: "existing user", email: "existinguser@example.com"})

      view = Pages.User.visit(conn, subject_user)

      assert %{
               "user_form[name]" => "existing user",
               "user_form[email]" => "existinguser@example.com",
               "user_form[type]" => "member",
               "user_form[status]" => "active"
             } = Pages.form_state(view)

      subject_user =
        Epicenter.AccountsFixtures.user_fixture(%{
          tid: "existinguser",
          admin: true,
          name: "existing user",
          disabled: true,
          email: "existinguser2@example.com"
        })

      view = Pages.User.visit(conn, subject_user)

      assert %{
               "user_form[name]" => "existing user",
               "user_form[email]" => "existinguser2@example.com",
               "user_form[type]" => "admin",
               "user_form[status]" => "inactive"
             } = Pages.form_state(view)
    end

    test "works", %{conn: conn} do
      %{id: id, hashed_password: hashed_password, mfa_secret: mfa_secret} =
        subject_user = Epicenter.AccountsFixtures.user_fixture(%{tid: "existing", admin: true, email: "existinguser@example.com"})

      view =
        Pages.User.visit(conn, subject_user)
        |> Pages.submit_and_follow_redirect(conn, "#user-form",
          user_form: %{"name" => "new name", "email" => "newemail@example.com", "type" => "member", "status" => "inactive"}
        )
        |> Pages.Users.assert_here()
        |> Pages.Users.assert_users([
          ["Name", "Email", "Type", "Status"],
          ["fixture admin", "admin@example.com", "Admin", "Active"],
          ["new name", "newemail@example.com", "Member", "Inactive"]
        ])

      assert %{
               id: ^id,
               hashed_password: ^hashed_password,
               mfa_secret: ^mfa_secret,
               name: "new name",
               email: "newemail@example.com",
               admin: false,
               disabled: true
             } = Accounts.get_user(email: "newemail@example.com")

      text = Pages.Users.password_reset_text(view)

      assert text == ""

      assert Accounts.get_user(email: "existinguser@example.com") == nil
    end
  end
end
