defmodule EpiViewpoint.Accounts do
  alias EpiViewpoint.Accounts.Admin
  alias EpiViewpoint.Accounts.Login
  alias EpiViewpoint.Accounts.User
  alias EpiViewpoint.Accounts.UserToken
  alias EpiViewpoint.Accounts.UserNotifier
  alias EpiViewpoint.AuditingRepo
  alias EpiViewpoint.Repo

  def change_login(attrs), do: Login.changeset(%Login{}, attrs)
  def change_user(%User{} = user, attrs), do: User.changeset(user, Enum.into(attrs, %{}))
  def change_user_mfa(user, mfa_secret), do: User.mfa_changeset(user, %{mfa_secret: mfa_secret})
  def change_user_password(user, attrs \\ %{}), do: User.password_changeset(user, attrs)
  def change_user_registration(%User{} = user, attrs \\ %{}), do: User.registration_changeset(user, attrs)
  def count_users(), do: User |> Repo.aggregate(:count)
  def create_login(attrs), do: change_login(attrs) |> Repo.insert()
  def get_user!(id) when is_binary(id), do: Repo.get!(User, id)
  def get_user(email: email) when is_binary(email), do: User |> Repo.get_by(email: email)
  def get_user(email: email, password: password), do: get_user(email: email) |> User.filter_by_valid_password(password)
  def get_user(id) when is_binary(id), do: User |> Repo.get(id)
  def list_recent_logins(user_id), do: Login.Query.most_recent_for_user_id(user_id) |> Repo.all()
  def list_users(), do: User.Query.all() |> Repo.all()
  def preload_assignments(user_or_users_or_nil), do: user_or_users_or_nil |> Repo.preload([:assignments])
  def register_user!({attrs, audit_meta}), do: %User{} |> change_user_registration(attrs) |> Admin.insert_by_admin!(audit_meta)
  def register_user({attrs, audit_meta}), do: %User{} |> change_user_registration(attrs) |> Admin.insert_by_admin(audit_meta)
  def update_user(%User{} = user, attrs, audit_meta), do: user |> change_user(attrs) |> Admin.update_by_admin(audit_meta)
  def update_user_mfa!(%User{} = user, {mfa_secret, audit_meta}), do: user |> change_user_mfa(mfa_secret) |> AuditingRepo.update!(audit_meta)

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, {token, audit_meta}) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context, audit_meta)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context, audit_meta) do
    changeset = user |> User.email_changeset(%{email: email}) |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.run(
      :user,
      fn _repo, _changes ->
        AuditingRepo.update(changeset, audit_meta)
      end
    )
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, {attrs, audit_meta}) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.run(
      :user,
      fn _repo, _changes ->
        AuditingRepo.update(changeset, audit_meta)
      end
    )
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {_token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
  end

  def session_token_status(token) do
    UserToken.fetch_user_token_query(token) |> Repo.one() |> UserToken.token_validity_status()
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {:ok, encoded_token} = generate_user_reset_password_token(user)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  def generate_user_reset_password_token(user) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    with {:ok, _} <- Repo.insert(user_token), do: {:ok, encoded_token}
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs, audit_meta) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(
      :user,
      fn _repo, _changes ->
        user
        |> User.password_changeset(attrs)
        |> User.confirm_changeset()
        |> AuditingRepo.update(audit_meta)
      end
    )
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end
end
