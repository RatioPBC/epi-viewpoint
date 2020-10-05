defmodule Epicenter.Release do
  alias Epicenter.Accounts
  alias EpicenterWeb.Endpoint
  alias EpicenterWeb.Router.Helpers, as: Routes

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

    [_body, url] = Regex.run(~r|\n(http://[^\n]+)\n|, body)
    url
  end

  defp ensure_started do
    Application.ensure_all_started(:ssl)
  end
end
