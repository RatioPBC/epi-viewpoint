defmodule Epicenter.Release do
  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias EpicenterWeb.Endpoint
  alias EpicenterWeb.Router.Helpers, as: Routes

  def create_user(%Epicenter.Accounts.User{} = author, name, email, opts \\ []) do
    ensure_started()

    puts = Keyword.get(opts, :puts, &IO.puts/1)
    puts.("Creating user #{name} / #{email}; they must set their password via this URL:")

    attrs = %{email: email, password: Euclid.Extra.Random.string(), name: name}

    audit_meta = %AuditLog.Meta{
      author_id: author.id,
      reason_action: AuditLog.Revision.releases_action(),
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

  @spec disable_users(list(String.t())) :: :ok
  def disable_users(emails, opts \\ []) do
    ensure_started()

    puts = Keyword.get(opts, :puts, &IO.puts/1)

    for email <- emails do
      with {:ok, user} <- get_user_by_email(email),
           {:ok, user} <- Epicenter.Accounts.disable_user(user) do
        puts.("Disabled user #{user.email}")
      else
        {:error, error} -> puts.("Error disabling #{email}: }#{error}")
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

  defp ensure_started do
    Application.ensure_all_started(:ssl)
  end
end
