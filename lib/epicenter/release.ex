defmodule Epicenter.Release do
  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias EpicenterWeb.Endpoint
  alias EpicenterWeb.Router.Helpers, as: Routes

  @app :epicenter

  #
  # DB management
  #

  def migrate do
    ensure_started()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    ensure_started()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  #
  # User management
  #

  @doc """
  An administrator can use `create_user` to make a user with a name and email.

  To do so, find your administrator's user:

  iex> administrator = Epicenter.Repo.get_by(Epicenter.Accounts.User, email: "admin@example.com")

  NOTE: For the very _first_ user, please use a fake/robot user with UUID "00000000-0000-0000-0000-000000000000"

  iex> administrator = %Epicenter.Accounts.User{id: "00000000-0000-0000-0000-000000000000"}

  Then call this function by providing a list of email addresses of users to disable:

  iex> Epicenter.Release.create_user(administrator, "Fred Durst", "limpbizkit@example.com")
  """

  def create_user(%Epicenter.Accounts.User{} = author, name, email, opts \\ []) do
    ensure_started()

    puts = Keyword.get(opts, :puts, &IO.puts/1)
    puts.("Creating user #{name} / #{email}; they must set their password via this URL:")

    attrs = %{email: email, password: Euclid.Extra.Random.string(), name: name}

    audit_meta = %AuditLog.Meta{
      author_id: author.id,
      reason_action: AuditLog.Revision.create_user_action(),
      reason_event: AuditLog.Revision.releases_event()
    }

    case Accounts.register_user({attrs, audit_meta}) do
      {:ok, user} ->
        {:ok, generated_password_reset_url(user)}

      {:error, %Ecto.Changeset{errors: errors}} ->
        puts.("FAILED!")
        {:error, errors}
    end
  end

  def reset_password(email) do
    {:ok, Accounts.get_user_by_email(email) |> generated_password_reset_url()}
  end

  @doc """
  An administrator can use `update_users` to disable users from being able to accomplish actions,
  or to re-enable them. To do so, find your administrator's user:

  administrator = Epicenter.Repo.get_by(Epicenter.Accounts.User, email: "admin@example.com")

  Then call this function by providing a list of email addresses of users to disable or enable:

  Epicenter.Release.update_users(administrator, ["some-other-user@example.com"], :disabled)
  Epicenter.Release.update_users(administrator, ["some-other-user@example.com"], :enabled)

  Progress will be logged to stdout.
  """
  @spec update_users(%Epicenter.Accounts.User{}, list(String.t()), atom()) :: :ok
  def update_users(author, emails, action, opts \\ []) when action in [:disabled, :enabled] do
    ensure_started()

    puts = Keyword.get(opts, :puts, &IO.puts/1)

    reason_action =
      case action do
        :disabled -> AuditLog.Revision.update_disabled_action()
        :enabled -> AuditLog.Revision.enable_user_action()
      end

    audit_meta = %AuditLog.Meta{
      author_id: author.id,
      reason_action: reason_action,
      reason_event: AuditLog.Revision.releases_event()
    }

    for email <- emails do
      with {:ok, user} <- get_user_by_email(email),
           {:ok, _user} <- Epicenter.Accounts.update_disabled(user, action, audit_meta) do
        puts.("OK: #{action} #{email}")
      else
        {:error, error} -> puts.("ERROR: #{action} #{email} (#{error})")
      end
    end

    :ok
  end

  @spec get_user_by_email(String.t()) :: {:ok, %Epicenter.Accounts.User{}} | {:error, String.t()}
  defp get_user_by_email(email) do
    case Epicenter.Repo.get_by(Epicenter.Accounts.User, email: email) do
      nil -> {:error, "NOT FOUND: user with email #{email}"}
      user -> {:ok, user}
    end
  end

  defp generated_password_reset_url(user) do
    {:ok, %{body: body}} =
      Accounts.deliver_user_reset_password_instructions(user, fn encoded_token ->
        Routes.user_reset_password_url(Endpoint, :edit, encoded_token)
      end)

    [_body, url] = Regex.run(~r|\n(https?://[^\n]+)\n|, body)
    url
  end

  #
  # other stuff
  #

  defp ensure_started do
    Application.ensure_all_started(:ssl)
  end
end
