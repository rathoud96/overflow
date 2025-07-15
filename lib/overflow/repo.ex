defmodule Overflow.Repo do
  use Ecto.Repo,
    otp_app: :overflow,
    adapter: Ecto.Adapters.Postgres
end
