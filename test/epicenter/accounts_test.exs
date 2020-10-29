defmodule Epicenter.AccountsTest do
  use Epicenter.DataCase, async: true

  import Epicenter.AccountsFixtures

  alias Epicenter.Accounts
  alias Epicenter.Accounts.User
  alias Epicenter.Accounts.UserToken
  alias Epicenter.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "user creation" do
    test "register_user creates a user with a user admin" do
      {:ok, user} = Test.Fixtures.user_attrs(@admin, "alice") |> Accounts.register_user()

      assert user.tid == "alice"
      assert user.name == "alice"

      assert_recent_audit_log(user, @admin, %{
        "tid" => "alice",
        "name" => "alice",
        "email" => "alice@example.com"
      })
    end

    test "register_user! creates a user with a user admin" do
      user = Test.Fixtures.user_attrs(@admin, "alice") |> Accounts.register_user!()

      assert user.tid == "alice"
      assert user.name == "alice"

      assert_recent_audit_log(user, @admin, %{
        "tid" => "alice",
        "name" => "alice",
        "email" => "alice@example.com"
      })
    end

    @ops_admin %Epicenter.Accounts.User{id: Application.get_env(:epicenter, :unpersisted_admin_id)}
    test "register_user creates a user with a ops admin" do
      {:ok, user} = Test.Fixtures.user_attrs(@ops_admin, "alice") |> Accounts.register_user()

      assert user.tid == "alice"
      assert user.name == "alice"

      assert_recent_audit_log(user, @ops_admin, %{
        "tid" => "alice",
        "name" => "alice",
        "email" => "alice@example.com"
      })
    end

    test "register_user fails when originator is not admin" do
      {:ok, phoney} = Test.Fixtures.user_attrs(@admin, "phoney") |> Accounts.register_user()
      user_count = length(Accounts.list_users())
      assert {:error, :admin_privileges_required} = Test.Fixtures.user_attrs(phoney, "alice") |> Accounts.register_user()
      assert ^user_count = length(Accounts.list_users())
    end

    test "register_user! fails when originator is not admin" do
      {:ok, phoney} = Test.Fixtures.user_attrs(@admin, "phoney") |> Accounts.register_user()
      user_count = length(Accounts.list_users())

      assert_raise Epicenter.AdminRequiredError, fn ->
        Test.Fixtures.user_attrs(phoney, "alice") |> Accounts.register_user!()
      end

      assert ^user_count = length(Accounts.list_users())
    end

    test "requires email and password to be set" do
      {:error, changeset} = Test.Fixtures.user_attrs(@admin, "missing_data", %{email: nil, password: nil}) |> Accounts.register_user()

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Test.Fixtures.user_attrs(@admin, "invalid_data", %{email: "not valid", password: "not valid"}) |> Accounts.register_user()

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["must be between 10 and 80 characters"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Test.Fixtures.user_attrs(@admin, "long_data", %{email: too_long, password: too_long}) |> Accounts.register_user()
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "must be between 10 and 80 characters" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      {:ok, user} = Test.Fixtures.user_attrs(@admin, "duplicate_email") |> Accounts.register_user()
      {:error, changeset} = Test.Fixtures.user_attrs(@admin, "duplicate_email") |> Accounts.register_user()
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Test.Fixtures.user_attrs(@admin, "duplicate_email", %{email: String.upcase(user.email)}) |> Accounts.register_user()
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()
      {:ok, user} = Test.Fixtures.user_attrs(@admin, "user", email: email, password: valid_user_password()) |> Accounts.register_user()
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end

    test "has an audit log" do
      email = unique_user_email()
      {:ok, user} = Test.Fixtures.user_attrs(@admin, "user", email: email, password: valid_user_password()) |> Accounts.register_user()

      assert_recent_audit_log(user, @admin, %{
        "tid" => "user",
        "name" => "user",
        "password" => "<<REDACTED>>",
        "email" => email
      })
    end
  end

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user(email: "unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      assert %User{id: ^id} = Accounts.get_user(email: user.email)
    end
  end

  describe "get_user by email and password" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user(email: "unknown@example.com", password: "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      refute Accounts.get_user(email: user.email, password: "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      assert %User{id: ^id} = Accounts.get_user(email: user.email, password: valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!("11111111-1111-1111-1111-111111111111")
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:password, :email, :name]
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: other_users_email} = Test.Fixtures.user_attrs(@admin, "user2") |> Accounts.register_user!()

      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{email: other_users_email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, "invalid", %{email: unique_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user} do
      email = unique_user_email()
      {:ok, user} = Accounts.apply_user_email(user, valid_user_password(), %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_mfa!/2" do
    test "creates a log event" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      Accounts.update_user_mfa!(user, {"123456", Test.Fixtures.audit_meta(@admin)})
      assert_revision_count(user, 2)

      assert_recent_audit_log(user, @admin, %{
        "mfa_secret" => "<<REDACTED>>"
      })
    end
  end

  describe "update_user_email/2" do
    setup do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    defp admin_audit_meta(), do: Test.Fixtures.audit_meta(@admin)

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Accounts.update_user_email(user, {token, admin_audit_meta()}) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "makes an audit log entry", %{user: user, token: token, email: email} do
      Accounts.update_user_email(user, {token, admin_audit_meta()})

      assert_recent_audit_log(user, @admin, %{
        "email" => email
      })
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, {"oops", admin_audit_meta()}) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, {token, admin_audit_meta()}) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, {token, admin_audit_meta()}) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end
  end

  describe "update_user_password/3" do
    setup do
      [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(
          user,
          valid_user_password(),
          {%{
             password: "not valid",
             password_confirmation: "another"
           }, Test.Fixtures.admin_audit_meta()}
        )

      assert %{
               password: ["must be between 10 and 80 characters"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Accounts.update_user_password(user, valid_user_password(), {%{password: too_long}, Test.Fixtures.admin_audit_meta()})

      assert "must be between 10 and 80 characters" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} = Accounts.update_user_password(user, "invalid", {%{password: valid_user_password()}, Test.Fixtures.admin_audit_meta()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(
          user,
          valid_user_password(),
          {%{
             password: "new valid password"
           }, Test.Fixtures.admin_audit_meta()}
        )

      assert is_nil(user.password)
      assert Accounts.get_user(email: user.email, password: "new valid password")

      assert_revision_count(user, 2)

      assert_recent_audit_log(user, @admin, %{
        "password" => "<<REDACTED>>"
      })
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, _} =
        Accounts.update_user_password(
          user,
          valid_user_password(),
          {%{
             password: "new valid password"
           }, Test.Fixtures.admin_audit_meta()}
        )

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      token = Accounts.generate_user_session_token(user)
      user_token = Repo.get_by(UserToken, token: token)
      [token: user_token]
    end

    test "generates a token with the normal 'session' context (not for password-reset)", %{token: user_token} do
      assert user_token.context == "session"
    end

    test "generates a unique token string (that is tied to exactly one user)", %{token: user_token} do
      other_user = Test.Fixtures.user_attrs(@admin, "user2") |> Accounts.register_user!()

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: other_user.id,
          context: "session"
        })
      end
    end

    test "generates a reasonable expiration date", %{token: user_token} do
      expected_expires_at = user_token.inserted_at |> DateTime.add(UserToken.default_token_lifetime())
      assert_datetime_approximate(user_token.expires_at, expected_expires_at)
    end
  end

  describe "session token status" do
    defp generate_expired_token() do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      {_, user_token} = UserToken.build_session_token(user)
      expires_at = DateTime.utc_now() |> DateTime.add(-1, :second) |> DateTime.truncate(:second)
      user_token |> Map.merge(%{expires_at: expires_at}) |> Repo.insert!()
    end

    defp generate_valid_token() do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      {_, user_token} = UserToken.build_session_token(user)
      user_token |> Repo.insert!()
    end

    test "when the token is expired" do
      user_token = generate_expired_token()

      assert Accounts.session_token_status(user_token.token) == :expired
    end

    test "when the token is not expired" do
      user_token = generate_valid_token()

      assert Accounts.session_token_status(user_token.token) == :valid
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "confirm_user/2" do
    setup do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "confirms the email with a valid token", %{user: user, token: token} do
      assert {:ok, confirmed_user} = Accounts.confirm_user(token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(User, user.id).confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user} do
      assert Accounts.confirm_user("oops") == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_user(token) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "generate_user_reset_password_token/2" do
    setup do
      [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
    end

    test "persists a reset password token's hash and returns the base64 encoded token", %{user: user} do
      {:ok, token} = Accounts.generate_user_reset_password_token(user)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(
          user,
          %{
            password: "not valid",
            password_confirmation: "another"
          },
          Test.Fixtures.audit_meta(user)
        )

      assert %{
               password: ["must be between 10 and 80 characters"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long}, Test.Fixtures.audit_meta(user))
      assert "must be between 10 and 80 characters" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "new valid password"}, Test.Fixtures.audit_meta(user))
      assert is_nil(updated_user.password)
      assert Accounts.get_user(email: user.email, password: "new valid password")
    end

    test "confirms the user", %{user: user} do
      assert user.confirmed_at == nil
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "new valid password"}, Test.Fixtures.audit_meta(user))
      assert updated_user.confirmed_at != nil
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.reset_user_password(user, %{password: "new valid password"}, Test.Fixtures.audit_meta(user))
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "updates the audit log", %{user: user} do
      {:ok, _updated_user} = Accounts.reset_user_password(user, %{password: "new valid password"}, Test.Fixtures.audit_meta(user))

      assert_revision_count(user, 2)

      assert_recent_audit_log(user, user, %{
        "password" => "<<REDACTED>>"
      })
    end
  end

  describe "update_user/2" do
    setup do
      [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
    end

    test "updates the provided user with a user admin", %{user: user} do
      strip_seq = fn map -> Map.put(map, :seq, nil) end

      attrs = %{admin: true, name: "Cool Admin", email: "newemail@example.com", disabled: true}
      assert {:ok, returned_user} = Accounts.update_user(user, attrs, Test.Fixtures.audit_meta(@admin))

      reloaded_user = Accounts.get_user!(user.id)

      assert %{admin: true, name: "Cool Admin", email: "newemail@example.com", disabled: true} = reloaded_user
      assert strip_seq.(reloaded_user) == strip_seq.(returned_user)
      assert_revision_count(reloaded_user, 2)

      assert_recent_audit_log(reloaded_user, @admin, %{"name" => "Cool Admin", "email" => "newemail@example.com", "disabled" => true, "admin" => true})
    end

    test "fails when originator is not admin", %{user: user} do
      {:ok, phoney} = Test.Fixtures.user_attrs(@admin, "phoney") |> Accounts.register_user()

      assert {:error, :admin_privileges_required} = Accounts.update_user(user, %{admin: true, name: "Cool Admin"}, Test.Fixtures.audit_meta(phoney))

      assert_revision_count(user, 1)
      refute Accounts.get_user!(user.id).admin
      assert Accounts.get_user!(user.id).name == "user"
    end

    test "fails when originator is the unpersisted admin (that's only supposed to be used for creating users)", %{user: user} do
      audit_meta = Test.Fixtures.audit_meta(%{id: Application.get_env(:epicenter, :unpersisted_admin_id)})

      user
      |> Accounts.update_user(%{admin: true, name: "Cool Admin"}, audit_meta)
      |> assert_eq({:error, :admin_privileges_required})
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
