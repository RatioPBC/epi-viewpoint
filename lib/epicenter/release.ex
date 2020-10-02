defmodule Epicenter.Release do
  alias Epicenter.Accounts
  alias EpicenterWeb.Endpoint
  alias EpicenterWeb.Router.Helpers, as: Routes

  def create_user(username, email) do
    ensure_started()

    IO.puts("Creating user #{username} / #{email}...")

    case Accounts.register_user(%{email: email, password: Euclid.Extra.Random.string(), username: username}) do
      {:ok, user} ->
        Accounts.deliver_user_reset_password_instructions(user, fn encoded_token ->
          url = Routes.user_reset_password_url(Endpoint, :edit, encoded_token)

          """

          Success! They must set their password via this URL:

          #{url}

          """
          |> IO.puts()
        end)

        :ok

      {:error, %Ecto.Changeset{errors: errors}} ->
        IO.puts("FAILED!")
        {:error, errors}
    end
  end

  defp ensure_started do
    Application.ensure_all_started(:ssl)
  end
end
