defmodule Epicenter.Test.Accounts do
  alias Epicenter.Accounts
  alias EpicenterWeb.Endpoint
  alias EpicenterWeb.Router.Helpers, as: Routes

  def confirm_user!(user) do
    Accounts.deliver_user_confirmation_instructions(user, fn encoded_token ->
      {:ok, _} = Accounts.confirm_user(encoded_token)
      Routes.user_confirmation_url(Endpoint, :confirm, encoded_token)
    end)
  end
end
