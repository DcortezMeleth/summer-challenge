defmodule SummerChallengeWeb.MyActivitiesLive do
  @moduledoc """
  LiveView for displaying and managing a user's activities.

  This module allows authenticated users to view their challenge activities
  and toggle their inclusion/exclusion status.
  """

  use SummerChallengeWeb, :live

  alias SummerChallenge.{Activities, Challenges}
  alias SummerChallengeWeb.Live.Components.ChallengeSelector

  @impl true
  def mount(_params, _session, socket) do
    # Load default challenge
    selected_challenge_id =
      case Challenges.get_default_challenge() do
        {:ok, challenge} -> challenge.id
        {:error, :no_challenges} -> nil
      end

    socket =
      socket
      |> assign(:selected_challenge_id, selected_challenge_id)
      |> assign(:toggling_activity_id, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    challenge_id = socket.assigns.selected_challenge_id
    user_id = socket.assigns.current_scope.user_id

    case load_activities_data(user_id, challenge_id) do
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

      <div class="px-4 py-6 max-w-7xl mx-auto">
        <header class="mb-8">
          <h1 class="text-3xl font-bold tracking-tight text-ui-900">
            My Activities
          </h1>
          <p class="mt-2 text-sm text-ui-700">
            Manage which activities count toward your challenge totals.
          </p>
        </header>

        <.sync_status_banner last_sync_label={@page.last_sync_label} />

        <.activity_error_banner :if={@page.error_message} error_message={@page.error_message} />

        <.activities_list
          activities={@page.activities}
          empty_message={@page.empty_message}
          toggling_activity_id={@toggling_activity_id}
        />
      </div>
    </.app_shell>
    """
  end

  @impl true
  def handle_event("toggle_exclusion", %{"activity_id" => activity_id}, socket) do
    user_id = socket.assigns.current_scope.user_id

    # Set the toggling state to disable the control
    socket = assign(socket, :toggling_activity_id, activity_id)

    case Activities.toggle_activity_exclusion(activity_id, user_id) do
      {:ok, %{excluded: excluded}} ->
        # Update the activity in the page data
        updated_activities =
          Enum.map(socket.assigns.page.activities, fn activity ->
            if activity.id == activity_id do
              %{activity | excluded: excluded}
            else
              activity
            end
          end)

        message = if excluded, do: "Activity excluded", else: "Activity included"

        socket =
          socket
          |> put_flash(:info, message)
          |> assign(:toggling_activity_id, nil)
          |> update(:page, fn page -> %{page | activities: updated_activities} end)

        {:noreply, socket}

      {:error, :unauthorized} ->
        socket =
          socket
          |> put_flash(:error, "You can only modify your own activities")
          |> assign(:toggling_activity_id, nil)

        {:noreply, socket}

      {:error, _reason} ->
        socket =
          socket
          |> put_flash(:error, "Failed to update activity")
          |> assign(:toggling_activity_id, nil)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:challenge_selected, challenge_id}, socket) do
    user_id = socket.assigns.current_scope.user_id

    socket =
      socket
      |> assign(:selected_challenge_id, challenge_id)

    case load_activities_data(user_id, challenge_id) do
      {:ok, page_data} ->
        {:noreply, assign(socket, :page, page_data)}

      {:error, _reason} ->
        page_data = build_error_page()
        {:noreply, assign(socket, :page, page_data)}
    end
  end

  # Private functions

  defp load_activities_data(_user_id, nil), do: {:error, :no_challenge}

  defp load_activities_data(user_id, challenge_id) do
    case Activities.get_user_activities(user_id, challenge_id) do
      {:ok, activities} ->
        # Get last sync time
        user = SummerChallenge.Accounts.get_user(user_id)

        last_sync_label =
          if user.last_synced_at do
            SummerChallengeWeb.Formatters.format_warsaw_datetime(user.last_synced_at)
          else
            "Never synced"
          end

        page = %{
          activities: activities,
          last_sync_label: last_sync_label,
          empty?: activities == [],
          empty_message: "No eligible activities found in the challenge window.",
          error_message: nil
        }

        {:ok, page}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_no_challenge_page do
    %{
      activities: [],
      last_sync_label: "Unknown",
      empty?: true,
      empty_message: "No challenge selected.",
      error_message: "Please select a challenge to view your activities."
    }
  end

  defp build_error_page do
    %{
      activities: [],
      last_sync_label: "Unknown",
      empty?: true,
      empty_message: "Unable to load activities.",
      error_message: "An error occurred while loading your activities. Please try again."
    }
  end

  # Component functions

  defp sync_status_banner(assigns) do
    ~H"""
    <div class="mb-6 rounded-lg bg-ui-50 border border-ui-200 px-4 py-3">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2 text-sm text-ui-700">
          <.icon name="hero-clock" class="w-5 h-5" />
          <span>Last sync: <span class="font-medium"><%= @last_sync_label %></span></span>
        </div>
      </div>
    </div>
    """
  end

  defp activity_error_banner(assigns) do
    ~H"""
    <div class="mb-6 rounded-lg bg-rose-50 border border-rose-200 px-4 py-3">
      <div class="flex items-center gap-2">
        <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-rose-600" />
        <p class="text-sm text-rose-700"><%= @error_message %></p>
      </div>
    </div>
    """
  end

  defp activities_list(assigns) do
    ~H"""
    <div class="bg-white shadow-sport rounded-2xl overflow-hidden ring-1 ring-ui-200">
      <%= if @empty_message && Enum.empty?(@activities) do %>
        <div class="px-6 py-12 text-center">
          <.icon name="hero-inbox" class="mx-auto h-12 w-12 text-ui-400" />
          <h3 class="mt-2 text-sm font-semibold text-ui-900">No activities</h3>
          <p class="mt-1 text-sm text-ui-600"><%= @empty_message %></p>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-ui-200">
            <thead class="bg-ui-50">
              <tr>
                <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Date & Time
                </th>
                <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Sport Type
                </th>
                <th scope="col" class="px-6 py-3 text-right text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Distance
                </th>
                <th scope="col" class="px-6 py-3 text-right text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Moving Time
                </th>
                <th scope="col" class="px-6 py-3 text-right text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Elevation
                </th>
                <th scope="col" class="px-6 py-3 text-center text-xs font-semibold text-ui-600 uppercase tracking-wider">
                  Include
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-ui-100">
              <tr
                :for={activity <- @activities}
                class={[
                  "hover:bg-ui-50 transition-colors",
                  activity.excluded && "opacity-50"
                ]}
              >
                <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-900">
                  <%= format_datetime(activity.start_at) %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={[
                    "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium",
                    sport_type_color(activity.sport_type)
                  ]}>
                    <%= activity.sport_type %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-700 text-right font-mono">
                  <%= SummerChallengeWeb.Formatters.format_km(activity.distance_m) %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-700 text-right font-mono">
                  <%= SummerChallengeWeb.Formatters.format_duration(activity.moving_time_s) %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-700 text-right font-mono">
                  <%= SummerChallengeWeb.Formatters.format_meters(activity.elev_gain_m) %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-center">
                  <input
                    type="checkbox"
                    checked={!activity.excluded}
                    disabled={@toggling_activity_id == activity.id}
                    phx-click="toggle_exclusion"
                    phx-value-activity_id={activity.id}
                    aria-label={"#{if activity.excluded, do: "Include", else: "Exclude"} activity on #{format_datetime(activity.start_at)} #{activity.sport_type}"}
                    class={[
                      "h-5 w-5 rounded border-ui-300 text-brand-600 focus:ring-brand-600 cursor-pointer",
                      @toggling_activity_id == activity.id && "opacity-50 cursor-not-allowed"
                    ]}
                  />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp format_datetime(datetime) do
    SummerChallengeWeb.Formatters.format_warsaw_datetime(datetime)
  end

  defp sport_type_color(sport_type) do
    cond do
      sport_type in ["Run", "TrailRun"] ->
        "bg-emerald-100 text-emerald-700 ring-1 ring-inset ring-emerald-600/20"

      sport_type in ["Ride", "GravelRide", "MountainBikeRide"] ->
        "bg-blue-100 text-blue-700 ring-1 ring-inset ring-blue-600/20"

      sport_type in ["VirtualRun"] ->
        "bg-purple-100 text-purple-700 ring-1 ring-inset ring-purple-600/20"

      sport_type in ["VirtualRide"] ->
        "bg-cyan-100 text-cyan-700 ring-1 ring-inset ring-cyan-600/20"

      true ->
        "bg-ui-100 text-ui-700 ring-1 ring-inset ring-ui-600/20"
    end
  end
end
