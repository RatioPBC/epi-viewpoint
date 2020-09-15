# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Epicenter.Repo.insert!(%Epicenter.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

if Application.get_env(:epicenter, :seeds_enabled?) do
  IO.puts("RUNNING SEEDS...")

  usernames = ["superuser", "Amy Admin", "Ida Investigator", "Tom Tracer"]
  existing_usernames = Epicenter.Accounts.list_users() |> Euclid.Extra.Enum.pluck(:username)
  new_usernames = usernames -- existing_usernames

  for username <- new_usernames do
    tid = Inflex.parameterize(username)
    IO.puts("Creating user: #{username} with tid #{tid}")
    Epicenter.Accounts.create_user!(%{username: username, tid: tid})
  end
end
