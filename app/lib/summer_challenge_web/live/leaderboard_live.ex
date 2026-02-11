defmodule SummerChallengeWeb.LeaderboardLive do
  @moduledoc """
  LiveView for displaying public leaderboards.

  This module handles the public leaderboard interface, allowing users to view
  running and cycling leaderboards without authentication. It validates sport
  parameters and loads leaderboard data from the Leaderboards context.
  """

  use SummerChallengeWeb, :live

  alias SummerChallenge.Leaderboards
  alias SummerChallengeWeb.ViewModels.Leaderboard, as: LeaderboardVM

  @impl true
  def mount(_params, _session, socket) do
    # Ensure auth context is available (should be set by auth hook, but provide defaults)
    socket =
      socket
      |> assign_new(:current_scope, fn -> %{authenticated?: false, user_id: nil} end)
      |> assign_new(:current_user, fn -> nil end)

    # Initialize with default sport if not set
    socket = assign(socket, :sport, :running)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"sport" => sport_param}, _uri, socket) do
    case validate_sport_param(sport_param) do
      {:ok, sport_category} ->
        case load_leaderboard_data(sport_category) do
          {:ok, page_data} ->
            socket =
              socket
              |> assign(:page, page_data)
              |> assign(:sport, sport_category)

            {:noreply, socket}

          {:error, reason} ->
            socket =
              socket
              |> assign(:page, build_error_page(sport_category, reason))
              |> assign(:sport, sport_category)

            {:noreply, socket}
        end

      {:error, :invalid_sport} ->
        # Redirect to running leaderboard for invalid sport params
        socket =
          socket
          |> put_flash(:info, "Unknown sport; showing running leaderboard.")
          |> push_navigate(to: "/leaderboard/running")

        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.app_shell>
      <:top_bar>
        <.auth_section current_scope={@current_scope} current_user={@current_user} />
      </:top_bar>

      <.sport_switch tabs={@page.tabs} />

      <div class="flex justify-between items-center px-4 py-2 bg-brand-50 border-b border-brand-100">
        <.sync_status_line last_sync_label={@page.last_sync_label} />
        <button
          :if={@current_scope.authenticated?}
          phx-click="refresh"
          class="text-sm font-medium text-brand-600 hover:text-brand-700 flex items-center gap-1"
        >
          <.icon name="hero-arrow-path" class="w-4 h-4" />
          Refresh Data
        </button>
      </div>

      <.error_banner :if={@page.error_message} error_message={@page.error_message} />

      <.leaderboard_table
        sport_label={@page.sport_label}
        rows={@page.rows}
        empty_message={@page.empty_message}
      />
    </.app_shell>
    """
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    if socket.assigns.current_scope.authenticated? do
      user_id = socket.assigns.current_scope.user_id
      require Logger
      Logger.info("Manual refresh triggered for user #{user_id}")

      case SummerChallenge.SyncService.sync_user(user_id) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Activities refreshed!")
           |> push_patch(to: "/leaderboard/#{socket.assigns.sport}")}

        {:error, reason} ->
          Logger.error("Manual refresh failed for user #{user_id}: #{inspect(reason)}")

          {:noreply,
           put_flash(socket, :error, "Failed to refresh activities: #{inspect(reason)}")}
      end
    else
      {:noreply, socket}
    end
  end

  # Private functions

  @spec validate_sport_param(String.t()) :: {:ok, :running | :cycling} | {:error, :invalid_sport}
  defp validate_sport_param("running"), do: {:ok, :running}
  defp validate_sport_param("cycling"), do: {:ok, :cycling}
  defp validate_sport_param(_), do: {:error, :invalid_sport}

  @spec sport_category_to_label(:running | :cycling) :: String.t()
  defp sport_category_to_label(:running), do: "Running"
  defp sport_category_to_label(:cycling), do: "Cycling"

  @spec load_leaderboard_data(:running | :cycling) ::
          {:ok, LeaderboardVM.page()} | {:error, term()}
  defp load_leaderboard_data(sport_category) do
    case Leaderboards.get_public_leaderboard(sport_category) do
      {:ok, %{entries: entries, last_sync_at: last_sync_at}} ->
        # Map DTOs to view models and build page data
        rows = Enum.map(entries, &LeaderboardVM.row/1)
        sport_label = sport_category_to_label(sport_category)

        tabs = [
          LeaderboardVM.tab(:running, "/leaderboard/running", sport_category == :running),
          LeaderboardVM.tab(:cycling, "/leaderboard/cycling", sport_category == :cycling)
        ]

        last_sync_label = SummerChallengeWeb.Formatters.format_warsaw_datetime(last_sync_at)

        page = LeaderboardVM.page(sport_category, sport_label, tabs, last_sync_label, rows, nil)
        {:ok, page}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec build_error_page(:running | :cycling, term()) :: LeaderboardVM.page()
  defp build_error_page(sport_category, _reason) do
    LeaderboardVM.error_page(
      sport_category,
      "Unable to load leaderboard right now. Please try again later."
    )
  end
end
