defmodule Epicenter.Accounts do
  alias Epicenter.Accounts.User
  alias Epicenter.Repo

  def change_user(%User{} = user, attrs), do: User.changeset(user, attrs)
  def create_user(attrs), do: %User{} |> change_user(attrs) |> Repo.insert()
  def create_user!(attrs), do: %User{} |> change_user(attrs) |> Repo.insert!()
end
