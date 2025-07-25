defmodule Overflow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Store application start time for health checks
    Application.put_env(:overflow, :start_time, System.system_time(:second))

    children = [
      OverflowWeb.Telemetry,
      Overflow.Repo,
      {DNSCluster, query: Application.get_env(:overflow, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Overflow.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Overflow.Finch},
      # Start a worker by calling: Overflow.Worker.start_link(arg)
      # {Overflow.Worker, arg},
      # Start to serve requests, typically the last entry
      OverflowWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Overflow.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OverflowWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
