defmodule Epicenter.Repo do
  use Ecto.Repo,
    otp_app: :epicenter,
    adapter: Ecto.Adapters.Postgres
end
