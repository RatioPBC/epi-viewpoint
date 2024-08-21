defmodule EpiViewpoint.Test.Accounts do
  alias EpiViewpoint.Accounts

  def confirm_user!(user) do
    Accounts.deliver_user_confirmation_instructions(user, fn encoded_token ->
      {:ok, _} = Accounts.confirm_user(encoded_token)
      ""
    end)

    user
  end
end
