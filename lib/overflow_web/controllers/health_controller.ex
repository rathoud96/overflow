defmodule OverflowWeb.HealthController do
  use OverflowWeb, :controller

  @moduledoc """
  Health check endpoints for monitoring and load balancers.
  """

  @doc """
  Basic health check endpoint.
  Returns 200 OK if the application is running.
  """
  def health(conn, _params) do
    json(conn, %{
      status: "ok",
      application: "overflow",
      version: Application.spec(:overflow, :vsn) |> to_string(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  @doc """
  Readiness probe - checks if application is ready to serve traffic.
  Includes database connectivity check.
  """
  def ready(conn, _params) do
    case check_database() do
      :ok ->
        json(conn, %{
          status: "ready",
          database: "connected",
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        })

      {:error, reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{
          status: "not_ready",
          database: "disconnected",
          error: to_string(reason),
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        })
    end
  end

  @doc """
  Liveness probe - checks if application is alive and should not be restarted.
  Simple check that the application is running.
  """
  def live(conn, _params) do
    json(conn, %{
      status: "alive",
      uptime: System.system_time(:second) - Application.get_env(:overflow, :start_time, 0),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  defp check_database do
    try do
      Overflow.Repo.query!("SELECT 1")
      :ok
    rescue
      exception -> {:error, exception.message}
    end
  end
end
