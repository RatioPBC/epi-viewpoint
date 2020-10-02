defmodule Epicenter.Release do
  alias Epicenter.Accounts
  alias EpicenterWeb.Endpoint
  alias EpicenterWeb.Router.Helpers, as: Routes

  def create_user(username, email) do
    ensure_started()

    IO.puts("Creating user #{username} / #{email}; they must set their password via this URL:")

    case Accounts.register_user(%{email: email, password: Euclid.Extra.Random.string(), username: username}) do
      {:ok, user} ->
        generated_password_reset_url(user)
        :ok

      {:error, %Ecto.Changeset{errors: errors}} ->
        IO.puts("FAILED!")
        {:error, errors}
    end
  end

  def reset_password(email) do
    Accounts.get_user_by_email(email) |> generated_password_reset_url()
    :ok
  end

  defp generated_password_reset_url(user) do
    Accounts.deliver_user_reset_password_instructions(user, fn encoded_token ->
      Routes.user_reset_password_url(Endpoint, :edit, encoded_token) |> IO.puts()
    end)
  end

  defp ensure_started do
    Application.ensure_all_started(:ssl)
  end
end
