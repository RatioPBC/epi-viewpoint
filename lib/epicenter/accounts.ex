defmodule Epicenter.Accounts do
  alias Epicenter.Accounts.User
  alias Epicenter.Repo

  def change_user(%User{} = user, attrs), do: User.changeset(user, attrs)
  def get_user(id), do: User |> Repo.get(id)
  def create_user(attrs), do: %User{} |> change_user(attrs) |> Repo.insert()
  def create_user!(attrs), do: %User{} |> change_user(attrs) |> Repo.insert!()
  def list_users(), do: User.Query.all() |> Repo.all()
  def preload_assignments(user_or_users_or_nil), do: user_or_users_or_nil |> Repo.preload([:assignments])
end
