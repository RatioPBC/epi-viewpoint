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

  iex> Epicenter.Release.create_user(administrator, "Fred Durst", "limpbizkit@example.com", :admin)
  """

  def create_user(%Epicenter.Accounts.User{} = author, name, email, level, opts \\ []) when level in [:member, :admin] do
    ensure_started()

    puts = Keyword.get(opts, :puts, &IO.puts/1)
    puts.("Creating user #{name} / #{email}; they must set their password via this URL:")

    attrs = %{email: email, password: Euclid.Extra.Random.string(), name: name, admin: level == :admin}

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
    {:ok, Accounts.get_user(email: email) |> generated_password_reset_url()}
  end

  @doc """
  An administrator can use `update_user` to manipulate a user's permissions,
  or to re-enable them. To do so, find your administrator's user:

  NOTE: The robot user cannot accomplish this task

  administrator = Epicenter.Repo.get_by(Epicenter.Accounts.User, email: "admin@example.com")

  Then call this function by providing a user's email to disable or enable the user with that email:

  Epicenter.Release.update_user(administrator, "some-other-user@example.com", :disabled)
  Epicenter.Release.update_user(administrator, "some-other-user@example.com", :enabled)

  Or call it with :admin to promote them to administrator:

  Epicenter.Release.update_user(administrator, "some-other-user@example.com", :admin)

  Or call it with :member to demote them to non-administrator:

  Epicenter.Release.update_user(administrator, "some-other-user@example.com", :member)

  stdout will tell you if your update worked
  """
  @spec update_user(%Epicenter.Accounts.User{}, String.t(), :disabled | :enabled | :admin | :member) :: :ok
  def update_user(author, email, action, opts \\ []) when action in [:disabled, :enabled, :admin, :member] do
    ensure_started()

    puts = Keyword.get(opts, :puts, &IO.puts/1)

    reason_action =
      case action do
        :disabled -> AuditLog.Revision.update_disabled_action()
        :enabled -> AuditLog.Revision.enable_user_action()
        :admin -> AuditLog.Revision.promote_user_action()
        :member -> AuditLog.Revision.demote_user_action()
      end

    audit_meta = %AuditLog.Meta{
      author_id: author.id,
      reason_action: reason_action,
      reason_event: AuditLog.Revision.releases_event()
    }

    attrs =
      case action do
        :disabled -> %{disabled: true}
        :enabled -> %{disabled: false}
        :admin -> %{admin: true}
        :member -> %{admin: false}
      end

    with user when not is_nil(user) <- Accounts.get_user(email: email),
         {:ok, _user} <- Epicenter.Accounts.update_user(user, attrs, audit_meta) do
      puts.("OK: #{action} #{email}")
    else
      nil -> puts.("Could not find a user with email #{email}")
      {:error, error} -> puts.("ERROR when trying to set #{email} to #{action} (#{inspect(error)})")
    end

    :ok
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
