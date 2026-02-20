defmodule SummerChallenge.Workers.StartupSyncCheck do
  @moduledoc """
  Checks on application startup whether a sync is needed and enqueues one if so.

  Guards against missed nightly syncs when the server was offline at midnight.
  A sync is triggered if the last sync across all users was more than 23 hours ago
  (or has never happened).
  """

  require Logger
  import Ecto.Query

  alias SummerChallenge.Model.User
  alias SummerChallenge.Repo
  alias SummerChallenge.Workers.SyncAllWorker

  @sync_threshold_hours 23

  @doc """
  Runs the startup sync check. Intended to be called from a supervised Task
  after Oban has started.
  """
  def run do
    last_synced_at = Repo.one(from u in User, select: max(u.last_synced_at))

    if sync_needed?(last_synced_at) do
      Logger.info("Startup sync check: last sync was #{format_age(last_synced_at)}, enqueuing catch-up sync")

      case %{} |> SyncAllWorker.new() |> Oban.insert() do
        {:ok, job} ->
          Logger.info("Startup catch-up sync job enqueued (id=#{job.id})")

        {:error, reason} ->
          Logger.error("Startup sync check: failed to enqueue sync job: #{inspect(reason)}")
      end
    else
      Logger.info("Startup sync check: last sync was #{format_age(last_synced_at)}, no catch-up needed")
    end
  end

  defp sync_needed?(nil), do: true

  defp sync_needed?(last_synced_at) do
    DateTime.diff(DateTime.utc_now(), last_synced_at, :hour) >= @sync_threshold_hours
  end

  defp format_age(nil), do: "never"

  defp format_age(last_synced_at) do
    hours = DateTime.diff(DateTime.utc_now(), last_synced_at, :hour)
    "#{hours}h ago"
  end
end
