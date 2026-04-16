defmodule SummerChallenge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias SummerChallenge.Workers.StartupSyncCheck

  @impl true
  def start(_type, _args) do
    children =
      [
        SummerChallengeWeb.Telemetry,
        SummerChallenge.Vault,
        SummerChallenge.Repo,
        {DNSCluster, query: Application.get_env(:summer_challenge, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: SummerChallenge.PubSub},
        # Start Oban for background job processing
        {Oban, Application.fetch_env!(:summer_challenge, Oban)}
      ]
      |> maybe_start_startup_sync_check()
      |> Kernel.++([
        # Start to serve requests, typically the last entry
        SummerChallengeWeb.Endpoint
      ])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SummerChallenge.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_start_startup_sync_check(children) do
    if Application.get_env(:summer_challenge, :run_startup_sync_check, true) do
      children ++
        [
          # On startup, enqueue a catch-up sync if the last sync was more than 23 hours ago
          {Task, fn -> StartupSyncCheck.run() end}
        ]
    else
      children
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SummerChallengeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
