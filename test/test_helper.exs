ExUnit.start()

# Configure ExMachina
{:ok, _} = Application.ensure_all_started(:ex_machina)

Mox.defmock(Overflow.SearchMock, for: Overflow.Search.Behaviour)
Mox.defmock(Overflow.RankingApiMock, for: Overflow.External.Ranking.Behaviour)

Ecto.Adapters.SQL.Sandbox.mode(Overflow.Repo, :manual)
