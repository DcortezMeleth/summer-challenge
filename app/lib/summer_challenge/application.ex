defmodule SummerChallenge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SummerChallengeWeb.Telemetry,
      SummerChallenge.Vault,
      SummerChallenge.Repo,
      {DNSCluster, query: Application.get_env(:summer_challenge, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SummerChallenge.PubSub},
      # Start a worker by calling: SummerChallenge.Worker.start_link(arg)
      # {SummerChallenge.Worker, arg},
      # Start the Quantum scheduler
      SummerChallenge.Scheduler,
      # Start to serve requests, typically the last entry
      SummerChallengeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SummerChallenge.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SummerChallengeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
