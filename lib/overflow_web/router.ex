defmodule OverflowWeb.Router do
  use OverflowWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  pipeline :api_optional_auth do
    plug :accepts, ["json"]
    plug CORSPlug
    plug OverflowWeb.Plugs.OptionalAuth
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug CORSPlug
    plug OverflowWeb.Plugs.RequireAuth
  end

  scope "/api", OverflowWeb do
    pipe_through :api
    post "/signup", AuthController, :signup
    post "/login", AuthController, :login
  end

  scope "/api", OverflowWeb do
    pipe_through :api_optional_auth
    post "/search", SearchController, :search
    post "/rerank", RerankController, :rerank
    post "/rerank-structured", RerankController, :rerank_structured
    get "/search/answers/:question_id", SearchController, :get_answers
  end

  scope "/api", OverflowWeb do
    pipe_through :api_auth
    get "/search/recent", SearchController, :recent_questions
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:overflow, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: OverflowWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
