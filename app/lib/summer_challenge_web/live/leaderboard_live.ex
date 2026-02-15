defmodule SummerChallengeWeb.LeaderboardLive do
  @moduledoc """
  LiveView for displaying public leaderboards.

  This module handles the public leaderboard interface, allowing users to view
  running and cycling leaderboards without authentication. It validates sport
  parameters and loads leaderboard data from the Leaderboards context.
  """

  use SummerChallengeWeb, :live

  alias SummerChallenge.{Leaderboards, Challenges}
  alias SummerChallengeWeb.ViewModels.Leaderboard, as: LeaderboardVM
  alias SummerChallengeWeb.Live.Components.ChallengeSelector

  @impl true
  def mount(_params, _session, socket) do
    # Ensure auth context is available (should be set by auth hook, but provide defaults)
    socket =
      socket
      |> assign_new(:current_scope, fn -> %{authenticated?: false, user_id: nil} end)
      |> assign_new(:current_user, fn -> nil end)

    # Initialize with default sport if not set
    socket = assign(socket, :sport, :running_outdoor)

    # Load default challenge
    selected_challenge_id =
      case Challenges.get_default_challenge() do
        {:ok, challenge} -> challenge.id
        {:error, :no_challenges} -> nil
      end

    socket = assign(socket, :selected_challenge_id, selected_challenge_id)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) when not is_map_key(params, "sport") do
    # No sport parameter provided - redirect to first available sport
    challenge_id = Map.get(params, "challenge_id", socket.assigns.selected_challenge_id)

    case load_challenge_sports(challenge_id) do
      {:ok, available_sports} ->
        first_sport = hd(available_sports)
        {:noreply, push_patch(socket, to: "/leaderboard/#{first_sport}")}

      {:error, :no_challenge} ->
        # No challenge available, still show page with error
        socket =
          socket
          |> assign(:page, build_no_challenge_page())
          |> assign(:sport, :running_outdoor)
          |> assign(:available_sports, [:running_outdoor, :cycling_outdoor])

        {:noreply, socket}
    end
  end

  @impl true
  def handle_params(%{"sport" => sport_param} = params, _uri, socket) do
    # Handle optional challenge_id from URL params
    challenge_id = Map.get(params, "challenge_id", socket.assigns.selected_challenge_id)

    socket = assign(socket, :selected_challenge_id, challenge_id)

    # Load challenge to get available sport groups
    case load_challenge_sports(challenge_id) do
      {:ok, available_sports} ->
        case validate_sport_param(sport_param, available_sports) do
          {:ok, sport_category} ->
            case load_leaderboard_data(sport_category, challenge_id, available_sports) do
              {:ok, page_data} ->
                socket =
                  socket
                  |> assign(:page, page_data)
                  |> assign(:sport, sport_category)
                  |> assign(:available_sports, available_sports)

                {:noreply, socket}

              {:error, reason} ->
                socket =
                  socket
                  |> assign(:page, build_error_page(sport_category, reason, available_sports))
                  |> assign(:sport, sport_category)
                  |> assign(:available_sports, available_sports)

                {:noreply, socket}
            end

          {:error, :sport_not_available} ->
            # Redirect to first available sport if current sport not available in challenge
            first_sport = hd(available_sports)

            socket =
              socket
              |> assign(:selected_challenge_id, challenge_id)
              |> put_flash(
                :info,
                "Sport not available for this challenge; showing #{format_sport_name(first_sport)}."
              )
              |> push_patch(to: "/leaderboard/#{first_sport}")

            {:noreply, socket}

          {:error, :invalid_sport} ->
            # Redirect to first available sport for invalid sport params
            first_sport = hd(available_sports)

            socket =
              socket
              |> assign(:selected_challenge_id, challenge_id)
              |> put_flash(:info, "Unknown sport; showing #{format_sport_name(first_sport)}.")
              |> push_patch(to: "/leaderboard/#{first_sport}")

            {:noreply, socket}
        end

      {:error, :no_challenge} ->
        # No challenge available, show error page
        socket =
          socket
          |> assign(:page, build_no_challenge_page())
          |> assign(:sport, :running_outdoor)
          |> assign(:available_sports, [:running_outdoor, :cycling_outdoor])

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

      <:challenge_selector>
        <.live_component
          module={ChallengeSelector}
          id="challenge-selector"
          selected_challenge_id={@selected_challenge_id}
          is_admin={@current_scope.is_admin}
        />
      </:challenge_selector>

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

  @impl true
  def handle_info({:challenge_selected, challenge_id}, socket) do
    # Reload page with new challenge
    {:noreply,
     socket
     |> assign(:selected_challenge_id, challenge_id)
     |> push_patch(to: "/leaderboard/#{socket.assigns.sport}")}
  end

  # Private functions

  @spec load_challenge_sports(binary() | nil) :: {:ok, [atom()]} | {:error, :no_challenge}
  defp load_challenge_sports(nil), do: {:error, :no_challenge}

  defp load_challenge_sports(challenge_id) do
    case Challenges.get_challenge(challenge_id) do
      {:ok, challenge} ->
        sports = SummerChallenge.Model.Challenge.active_sport_groups(challenge)

        # Ensure we have at least one sport
        case sports do
          # Fallback if challenge has no sports configured
          [] -> {:ok, [:running_outdoor, :cycling_outdoor]}
          sports -> {:ok, sports}
        end

      {:error, _} ->
        {:error, :no_challenge}
    end
  end

  @spec validate_sport_param(String.t(), [atom()]) ::
          {:ok, atom()} | {:error, :invalid_sport | :sport_not_available}
  defp validate_sport_param(sport_param, available_sports) do
    sport_atom = String.to_existing_atom(sport_param)

    if sport_atom in available_sports do
      {:ok, sport_atom}
    else
      {:error, :sport_not_available}
    end
  rescue
    ArgumentError -> {:error, :invalid_sport}
  end

  @spec sport_category_to_label(atom()) :: String.t()
  defp sport_category_to_label(:running_outdoor), do: "Running (Outdoor)"
  defp sport_category_to_label(:cycling_outdoor), do: "Cycling (Outdoor)"
  defp sport_category_to_label(:running_virtual), do: "Running (Virtual)"
  defp sport_category_to_label(:cycling_virtual), do: "Cycling (Virtual)"

  defp sport_category_to_label(sport),
    do:
      sport
      |> to_string()
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

  @spec format_sport_name(atom()) :: String.t()
  defp format_sport_name(sport), do: sport_category_to_label(sport)

  @spec load_leaderboard_data(atom(), binary() | nil, [atom()]) ::
          {:ok, LeaderboardVM.page()} | {:error, term()}
  defp load_leaderboard_data(sport_category, challenge_id, available_sports) do
    case Leaderboards.get_public_leaderboard(sport_category, challenge_id: challenge_id) do
      {:ok, %{entries: entries, last_sync_at: last_sync_at}} ->
        # Map DTOs to view models and build page data
        rows = Enum.map(entries, &LeaderboardVM.row/1)
        sport_label = sport_category_to_label(sport_category)

        # Generate tabs dynamically based on available sports
        tabs = build_sport_tabs(available_sports, sport_category)

        last_sync_label = SummerChallengeWeb.Formatters.format_warsaw_datetime(last_sync_at)

        page = LeaderboardVM.page(sport_category, sport_label, tabs, last_sync_label, rows, nil)
        {:ok, page}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec build_sport_tabs([atom()], atom()) :: [LeaderboardVM.tab()]
  defp build_sport_tabs(available_sports, current_sport) do
    available_sports
    |> Enum.map(fn sport ->
      LeaderboardVM.tab(
        sport,
        "/leaderboard/#{sport}",
        sport == current_sport
      )
    end)
  end

  @spec build_error_page(atom(), term(), [atom()]) :: LeaderboardVM.page()
  defp build_error_page(sport_category, _reason, available_sports) do
    tabs = build_sport_tabs(available_sports, sport_category)

    %LeaderboardVM.Page{
      sport: sport_category,
      sport_label: sport_category_to_label(sport_category),
      tabs: tabs,
      last_sync_label: "Unknown",
      rows: [],
      empty_message: "Unable to load leaderboard. Please try again later.",
      error_message: "Unable to load leaderboard right now. Please try again later."
    }
  end

  @spec build_no_challenge_page() :: LeaderboardVM.page()
  defp build_no_challenge_page do
    %LeaderboardVM.Page{
      sport: :running_outdoor,
      sport_label: "Running (Outdoor)",
      tabs: [],
      last_sync_label: "Unknown",
      rows: [],
      empty_message: "No challenges available.",
      error_message: "No challenges are currently configured. Please contact an administrator."
    }
  end
end
