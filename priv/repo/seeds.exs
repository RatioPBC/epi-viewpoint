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
