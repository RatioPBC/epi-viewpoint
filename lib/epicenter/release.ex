defmodule Epicenter.Release do
  alias Epicenter.Accounts
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

  def seeds do
    IO.puts("RUNNING SEEDS...")

    existing_user_tids = Epicenter.Accounts.list_users() |> Euclid.Extra.Enum.pluck(:tid)

    new_users =
      [{"superuser", "Sal Superuser"}, {"admin", "Amy Admin"}, {"investigator", "Ida Investigator"}, {"tracer", "Tom Tracer"}]
      |> Enum.reject(fn {tid, _name} -> tid in existing_user_tids end)

    for {tid, name} <- new_users do
      email = "#{tid}@example.com"
      password = "password123"

      IO.puts("Creating #{name} / #{email} / #{password}")
      Epicenter.Accounts.register_user!(%{email: email, password: password, tid: tid, name: name})
    end
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  #
  # User management
  #

  def create_user(name, email, opts \\ []) do
    ensure_started()

    puts = Keyword.get(opts, :puts, &IO.puts/1)
    puts.("Creating user #{name} / #{email}; they must set their password via this URL:")

    case Accounts.register_user(%{email: email, password: Euclid.Extra.Random.string(), name: name}) do
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
