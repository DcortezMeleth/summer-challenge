defmodule SummerChallenge.Workers.SyncAllWorker do
  @moduledoc """
  Oban worker for synchronizing all users' activities.

  This worker is scheduled to run daily at midnight Europe/Warsaw time.
  It fetches activities from Strava for all users with valid credentials.
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    unique: [period: 3600, states: [:available, :scheduled, :executing]]

  alias SummerChallenge.SyncService

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("Starting scheduled sync for all users")

    case SyncService.sync_all() do
      %{total: total, success: success, error: error} = result ->
        Logger.info("Sync completed: #{success}/#{total} successful, #{error} errors")

        {:ok, result}

      {:error, reason} = error ->
        Logger.error("Sync failed: #{inspect(reason)}")
        error
    end
  end
end
