defmodule SummerChallengeWeb.LeaderboardLive do
  @moduledoc """
  LiveView for displaying public leaderboards.

  This module handles the public leaderboard interface, allowing users to view
  running and cycling leaderboards without authentication. It validates sport
  parameters and loads leaderboard data from the Leaderboards context.
  """

  use SummerChallengeWeb, :live

  alias SummerChallenge.Challenges
  alias SummerChallenge.Leaderboards
  alias SummerChallengeWeb.Live.Components.ChallengeSelector
  alias SummerChallengeWeb.ViewModels.Leaderboard, as: LeaderboardVM

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:sport, :running_outdoor)
      |> assign(:team_rows, [])

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
    socket =
      case load_challenge_sports(challenge_id) do
        {:ok, available_sports} ->
          handle_sport_validation(socket, sport_param, challenge_id, available_sports)

        {:error, :no_challenge} ->
          handle_no_challenge(socket)
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main id="main-content" class="min-h-screen bg-gradient-to-b from-brand-50 via-ui-50 to-ui-50" role="main">
      <div class="mx-auto max-w-5xl px-4 py-10">
        <header class="mb-8">
          <div class="flex items-start justify-between gap-4">
            <div class="flex-1">
              <p class="text-xs font-semibold tracking-widest text-orange-500 uppercase">
                Summer Challenge
              </p>
              <h1 class="mt-2 text-3xl font-bold tracking-tight text-ui-900">
                Leaderboards
              </h1>
              <p class="mt-2 text-sm text-ui-700 max-w-prose">
                Outdoor-only totals for running and cycling. Compete hard, move smart.
              </p>
            </div>
            <div class="flex-shrink-0 min-w-[20rem]">
              <.live_component
                module={ChallengeSelector}
                id="challenge-selector"
                selected_challenge_id={@selected_challenge_id}
                is_admin={@current_scope.is_admin}
              />
            </div>
          </div>
        </header>

        <.sport_switch tabs={@page.tabs} />

        <div class="flex justify-between items-center px-4 py-2 bg-brand-50 border-b border-brand-100">
          <.sync_status_line last_sync_label={@page.last_sync_label} />
          <button
            :if={@current_scope.authenticated?}
            phx-click="refresh"
            class="text-sm font-medium text-orange-500 hover:text-orange-600 flex items-center gap-1"
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

        <.team_standings_section :if={@team_rows != []} team_rows={@team_rows} sport_label={@page.sport_label} />
      </div>
    </main>
    """
  end

  defp team_standings_section(assigns) do
    ~H"""
    <section class="mt-8" aria-label="Team Standings">
      <h2 class="text-lg font-semibold text-ui-900 mb-3 flex items-center gap-2">
        <.icon name="hero-user-group" class="w-5 h-5 text-brand-600" />
        Team Standings
        <span class="text-sm font-normal text-ui-500">· <%= @sport_label %></span>
      </h2>

      <div class="bg-white/90 shadow-sport rounded-2xl overflow-hidden ring-1 ring-ui-200">
        <div class="overflow-x-auto">
          <table class="min-w-[40rem] w-full divide-y divide-ui-200" aria-label="Team Standings">
            <thead class="bg-ui-50">
              <tr>
                <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Rank
                </th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Team
                </th>
                <th scope="col" class="px-6 py-3 text-right text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Distance
                </th>
                <th scope="col" class="px-6 py-3 text-right text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Time
                </th>
                <th scope="col" class="px-6 py-3 text-right text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Elevation
                </th>
                <th scope="col" class="px-6 py-3 text-right text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Activities
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-ui-100">
              <tr :for={row <- @team_rows} class="odd:bg-white even:bg-ui-50 hover:bg-brand-50/70 transition-colors">
                <td class="px-6 py-4 whitespace-nowrap text-sm tabular-nums">
                  <span class={[
                    "inline-flex items-center justify-center h-7 min-w-7 px-2 rounded-full font-bold",
                    case row.rank do
                      1 -> "bg-amber-400 text-amber-900 ring-1 ring-amber-500/50 shadow-sm"
                      2 -> "bg-slate-200 text-slate-600 ring-1 ring-slate-400/50"
                      3 -> "bg-orange-100 text-orange-800 ring-1 ring-orange-400/50"
                      _ -> "bg-ui-100 text-ui-900"
                    end
                  ]}>
                    <%= row.rank %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-ui-900">
                  <div class="flex items-center gap-2">
                    <.icon name="hero-user-group" class="w-4 h-4 text-brand-500 flex-shrink-0" />
                    <%= row.team_name %>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-sky-700 font-medium text-right tabular-nums">
                  <%= row.distance_label %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-sky-700 font-medium text-right tabular-nums">
                  <%= row.moving_time_label %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-sky-700 font-medium text-right tabular-nums">
                  <%= row.elev_gain_label %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-sky-700 font-medium text-right tabular-nums">
                  <%= row.activity_count_label %>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>
    """
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    if socket.assigns.current_scope.authenticated? do
      require Logger

      user_id = socket.assigns.current_scope.user_id
      Logger.info("Manual refresh triggered for user #{user_id}")

      case SummerChallenge.SyncService.sync_user(user_id) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Activities refreshed!")
           |> push_patch(to: "/leaderboard/#{socket.assigns.sport}")}

        {:error, reason} ->
          Logger.error("Manual refresh failed for user #{user_id}: #{inspect(reason)}")

          {:noreply, put_flash(socket, :error, "Failed to refresh activities: #{inspect(reason)}")}
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

  defp handle_sport_validation(socket, sport_param, challenge_id, available_sports) do
    case validate_sport_param(sport_param, available_sports) do
      {:ok, sport_category} ->
        handle_sport_loading(socket, sport_category, challenge_id, available_sports)

      {:error, :sport_not_available} ->
        redirect_to_first_sport(
          socket,
          challenge_id,
          available_sports,
          "Sport not available for this challenge"
        )

      {:error, :invalid_sport} ->
        redirect_to_first_sport(socket, challenge_id, available_sports, "Unknown sport")
    end
  end

  defp handle_sport_loading(socket, sport_category, challenge_id, available_sports) do
    case load_leaderboard_data(sport_category, challenge_id, available_sports) do
      {:ok, page_data, team_rows} ->
        socket
        |> assign_sport_page(page_data, sport_category, available_sports)
        |> assign(:team_rows, team_rows)

      {:error, reason} ->
        socket
        |> assign_error_page(sport_category, reason, available_sports)
        |> assign(:team_rows, [])
    end
  end

  defp redirect_to_first_sport(socket, challenge_id, available_sports, message) do
    first_sport = hd(available_sports)

    socket
    |> assign(:selected_challenge_id, challenge_id)
    |> put_flash(:info, "#{message}; showing #{format_sport_name(first_sport)}.")
    |> push_patch(to: "/leaderboard/#{first_sport}")
  end

  defp assign_sport_page(socket, page_data, sport_category, available_sports) do
    socket
    |> assign(:page, page_data)
    |> assign(:sport, sport_category)
    |> assign(:available_sports, available_sports)
  end

  defp assign_error_page(socket, sport_category, reason, available_sports) do
    socket
    |> assign(:page, build_error_page(sport_category, reason, available_sports))
    |> assign(:sport, sport_category)
    |> assign(:available_sports, available_sports)
  end

  defp handle_no_challenge(socket) do
    socket
    |> assign(:page, build_no_challenge_page())
    |> assign(:sport, :running_outdoor)
    |> assign(:available_sports, [:running_outdoor, :cycling_outdoor])
    |> assign(:team_rows, [])
  end

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
    do: sport |> to_string() |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)

  @spec format_sport_name(atom()) :: String.t()
  defp format_sport_name(sport), do: sport_category_to_label(sport)

  @spec load_leaderboard_data(atom(), binary() | nil, [atom()]) ::
          {:ok, LeaderboardVM.page(), [map()]} | {:error, term()}
  defp load_leaderboard_data(sport_category, challenge_id, available_sports) do
    case Leaderboards.get_public_leaderboard(sport_category, challenge_id: challenge_id) do
      {:ok, %{entries: entries, last_sync_at: last_sync_at}} ->
        rows = Enum.map(entries, &LeaderboardVM.row/1)
        sport_label = sport_category_to_label(sport_category)
        tabs = build_sport_tabs(available_sports, sport_category)
        last_sync_label = SummerChallengeWeb.Formatters.format_warsaw_datetime(last_sync_at)
        page = LeaderboardVM.page(sport_category, sport_label, tabs, last_sync_label, rows, nil)

        team_rows = load_team_rows(sport_category, challenge_id)

        {:ok, page, team_rows}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec load_team_rows(atom(), binary() | nil) :: [map()]
  defp load_team_rows(sport_category, challenge_id) do
    case Leaderboards.get_team_leaderboard(sport_category, challenge_id: challenge_id) do
      {:ok, %{entries: entries}} ->
        Enum.map(entries, fn entry ->
          %{
            rank: entry.rank,
            team_name: entry.team.name,
            distance_label: SummerChallengeWeb.Formatters.format_km(entry.totals.distance_m),
            moving_time_label:
              SummerChallengeWeb.Formatters.format_duration(entry.totals.moving_time_s),
            elev_gain_label:
              SummerChallengeWeb.Formatters.format_meters(entry.totals.elev_gain_m),
            activity_count_label: Integer.to_string(entry.totals.activity_count)
          }
        end)

      {:error, _} ->
        []
    end
  end

  @spec build_sport_tabs([atom()], atom()) :: [LeaderboardVM.tab()]
  defp build_sport_tabs(available_sports, current_sport) do
    Enum.map(available_sports, fn sport ->
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
