defmodule Remit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RemitWeb.Telemetry,
      Remit.Repo,
      {DNSCluster, query: Application.get_env(:remit, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Remit.PubSub},
      # Start a worker by calling: Remit.Worker.start_link(arg)
      # {Remit.Worker, arg},
      # Start to serve requests, typically the last entry
      RemitWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Remit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RemitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
