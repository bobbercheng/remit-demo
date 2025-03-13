defmodule RemitWeb.Router do
  use RemitWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", RemitWeb do
    pipe_through :api
  end
end
