defmodule SummerChallengeWeb.MilestoneLive do
  @moduledoc """
  LiveView for displaying the 40-hour milestone achievers.

  This module shows users who have reached the 40-hour moving time threshold
  for the selected challenge.
  """

  use SummerChallengeWeb, :live

  alias SummerChallenge.{Milestones, Challenges}
  alias SummerChallengeWeb.Live.Components.ChallengeSelector

  @impl true
  def mount(_params, _session, socket) do
    # Ensure auth context is available
    socket =
      socket
      |> assign_new(:current_scope, fn -> %{authenticated?: false, user_id: nil} end)
      |> assign_new(:current_user, fn -> nil end)

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
  def handle_params(_params, _uri, socket) do
    challenge_id = socket.assigns.selected_challenge_id

    case load_milestone_data(challenge_id) do
      {:ok, page_data} ->
        {:noreply, assign(socket, :page, page_data)}

      {:error, :no_challenge} ->
        page_data = build_no_challenge_page()
        {:noreply, assign(socket, :page, page_data)}

      {:error, _reason} ->
        page_data = build_error_page()
        {:noreply, assign(socket, :page, page_data)}
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

      <div class="px-4 py-6">
        <header class="mb-8 text-center">
          <h1 class="text-3xl font-bold tracking-tight text-ui-900">
            40-Hour Milestone
          </h1>
          <p class="mt-2 text-sm text-ui-700 max-w-2xl mx-auto">
            Congratulations to everyone who reached <%= @page.threshold_hours %> hours of moving time!
            Keep pushing toward your fitness goals.
          </p>
        </header>

        <div class="flex justify-between items-center px-4 py-2 bg-brand-50 border-b border-brand-100 mb-6">
          <.milestone_sync_status last_sync_label={@page.last_sync_label} />
        </div>

        <.milestone_error_banner :if={@page.error_message} error_message={@page.error_message} />

        <.achievers_list
          achievers={@page.achievers}
          empty_message={@page.empty_message}
          threshold_hours={@page.threshold_hours}
        />
      </div>
    </.app_shell>
    """
  end

  @impl true
  def handle_info({:challenge_selected, challenge_id}, socket) do
    socket = assign(socket, :selected_challenge_id, challenge_id)

    case load_milestone_data(challenge_id) do
      {:ok, page_data} ->
        {:noreply, assign(socket, :page, page_data)}

      {:error, _reason} ->
        page_data = build_error_page()
        {:noreply, assign(socket, :page, page_data)}
    end
  end

  # Private functions

  defp load_milestone_data(nil), do: {:error, :no_challenge}

  defp load_milestone_data(challenge_id) do
    case Milestones.get_milestone_achievers(challenge_id: challenge_id) do
      {:ok, %{achievers: achievers, last_sync_at: last_sync_at}} ->
        last_sync_label = SummerChallengeWeb.Formatters.format_warsaw_datetime(last_sync_at)
        threshold_hours = Milestones.milestone_threshold_hours()

        page = %{
          achievers: achievers,
          last_sync_label: last_sync_label,
          threshold_hours: threshold_hours,
          empty?: achievers == [],
          empty_message: "No one has reached #{threshold_hours} hours yet. Be the first!",
          error_message: nil
        }

        {:ok, page}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_no_challenge_page do
    threshold_hours = Milestones.milestone_threshold_hours()
    
    %{
      achievers: [],
      last_sync_label: "Unknown",
      threshold_hours: threshold_hours,
      empty?: true,
      empty_message: "No challenge selected.",
      error_message: "Please select a challenge to view milestone achievers."
    }
  end

  defp build_error_page do
    threshold_hours = Milestones.milestone_threshold_hours()
    
    %{
      achievers: [],
      last_sync_label: "Unknown",
      threshold_hours: threshold_hours,
      empty?: true,
      empty_message: "Unable to load milestone data.",
      error_message: "An error occurred while loading milestone achievers. Please try again."
    }
  end

  # Component functions

  defp milestone_sync_status(assigns) do
    ~H"""
    <div class="flex items-center gap-2 text-sm text-ui-700">
      <.icon name="hero-clock" class="w-5 h-5" />
      <span>Last sync: <span class="font-medium"><%= @last_sync_label %></span></span>
    </div>
    """
  end

  defp milestone_error_banner(assigns) do
    ~H"""
    <div class="mb-6 rounded-lg bg-rose-50 border border-rose-200 px-4 py-3">
      <div class="flex items-center gap-2">
        <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-rose-600" />
        <p class="text-sm text-rose-700"><%= @error_message %></p>
      </div>
    </div>
    """
  end

  defp achievers_list(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <div class="bg-white shadow-sport rounded-2xl overflow-hidden ring-1 ring-ui-200">
        <%= if @empty_message && Enum.empty?(@achievers) do %>
          <div class="px-6 py-16 text-center">
            <.icon name="hero-trophy" class="mx-auto h-16 w-16 text-ui-400" />
            <h3 class="mt-4 text-lg font-semibold text-ui-900">No Achievers Yet</h3>
            <p class="mt-2 text-sm text-ui-600"><%= @empty_message %></p>
            <p class="mt-4 text-xs text-ui-500">
              The <%= @threshold_hours %>-hour milestone is a significant achievement. Keep training!
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-ui-200">
              <thead class="bg-ui-50">
                <tr>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                    Participant
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                    Team
                  </th>
                  <th scope="col" class="px-6 py-3 text-right text-xs font-semibold text-ui-600 uppercase tracking-wider">
                    Total Moving Time
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-ui-100">
                <tr
                  :for={achiever <- @achievers}
                  class="hover:bg-ui-50 transition-colors"
                >
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center gap-2">
                      <.icon name="hero-trophy" class="w-5 h-5 text-amber-500" />
                      <span class="text-sm font-semibold text-ui-900">
                        <%= achiever.user.display_name %>
                      </span>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-700">
                    <%= normalize_team_name(achiever.user.team_name) %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-900 text-right font-mono font-semibold">
                    <%= format_moving_time(achiever.total_moving_time_s) %>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="px-6 py-4 bg-ui-50 border-t border-ui-200">
            <p class="text-xs text-ui-600 text-center">
              Showing <%= length(@achievers) %> <%= if length(@achievers) == 1, do: "participant", else: "participants" %> who reached the <%= @threshold_hours %>-hour milestone
            </p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_moving_time(seconds) do
    SummerChallengeWeb.Formatters.format_duration(seconds)
  end

  defp normalize_team_name(team_name) when is_binary(team_name) do
    if String.trim(team_name) == "", do: "—", else: team_name
  end

  defp normalize_team_name(_), do: "—"
end
