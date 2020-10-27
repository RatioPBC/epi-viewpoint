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
    [
      {"superuser", "Sal Superuser", true},
      {"admin", "Amy Admin", true},
      {"investigator", "Ida Investigator", false},
      {"tracer", "Tom Tracer", false}
    ]
    |> Enum.reject(fn {tid, _name, _admin?} -> tid in existing_user_tids end)

  for {tid, name, admin?} <- new_users do
    email = "#{tid}@example.com"
    password = "password123"

    IO.puts("Creating #{name} / #{email} / #{password}")

    Epicenter.Accounts.register_user!({
      %{email: email, password: password, tid: tid, name: name, admin: admin?},
      %Epicenter.AuditLog.Meta{
        author_id: Application.get_env(:epicenter, :unpersisted_admin_id),
        reason_action: Epicenter.AuditLog.Revision.register_user_action(),
        reason_event: Epicenter.AuditLog.Revision.seed_event()
      }
    })
  end
end
