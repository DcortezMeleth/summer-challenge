defmodule SummerChallengeWeb.Live.Components.ChallengeSelector do
  @moduledoc """
  LiveComponent for selecting challenges from a dropdown.

  Displays challenges ordered by:
  - Active challenges first (by start_date descending)
  - Then inactive challenges (by start_date descending)
  - Archived challenges are hidden from non-admin users

  Emits a "challenge_selected" event when a user selects a different challenge.
  """
  use Phoenix.LiveComponent

  import SummerChallengeWeb.CoreComponents

  alias SummerChallenge.Challenges

  @impl true
  def update(assigns, socket) do
    is_admin = Map.get(assigns, :is_admin, false)
    selected_challenge_id = Map.get(assigns, :selected_challenge_id)

    # Load challenges for selector
    challenges = Challenges.list_challenges_for_selector(is_admin)

    # Determine selected challenge
    selected_challenge_id =
      selected_challenge_id || get_default_challenge_id(challenges)

    {:ok,
     socket
     |> assign(:challenges, challenges)
     |> assign(:selected_challenge_id, selected_challenge_id)
     |> assign(:is_admin, is_admin)
     |> assign(:dropdown_open, false)}
  end

  @impl true
  def handle_event("toggle_dropdown", _params, socket) do
    {:noreply, assign(socket, :dropdown_open, !socket.assigns.dropdown_open)}
  end

  @impl true
  def handle_event("select_challenge", %{"challenge_id" => challenge_id}, socket) do
    # Notify parent LiveView of the selection
    send(self(), {:challenge_selected, challenge_id})

    {:noreply,
     socket
     |> assign(:selected_challenge_id, challenge_id)
     |> assign(:dropdown_open, false)}
  end

  @impl true
  def handle_event("close_dropdown", _params, socket) do
    {:noreply, assign(socket, :dropdown_open, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative" id="challenge-selector" phx-click-away="close_dropdown" phx-target={@myself}>
      <button
        type="button"
        phx-click="toggle_dropdown"
        phx-target={@myself}
        aria-haspopup="true"
        aria-expanded={@dropdown_open}
        class="inline-flex items-center justify-between w-full rounded-lg bg-white px-4 py-2.5 text-sm font-semibold text-ui-900 shadow-sm ring-1 ring-ui-300 hover:bg-ui-50 focus:outline-none focus:ring-2 focus:ring-brand-600 transition-colors"
      >
        <span class="flex items-center gap-2">
          <.icon name="hero-calendar" class="w-5 h-5 text-brand-600" />
          <span><%= selected_challenge_name(@challenges, @selected_challenge_id) %></span>
        </span>
        <.icon name={if @dropdown_open, do: "hero-chevron-up", else: "hero-chevron-down"} class="w-5 h-5 text-ui-500" />
      </button>

      <div
        :if={@dropdown_open}
        class="absolute z-10 mt-2 w-full min-w-[20rem] origin-top-right rounded-lg bg-white shadow-lg ring-1 ring-ui-300 focus:outline-none"
        role="menu"
        aria-orientation="vertical"
        aria-labelledby="challenge-selector"
      >
        <div class="py-1 max-h-96 overflow-y-auto">
          <button
            :for={challenge <- @challenges}
            type="button"
            phx-click="select_challenge"
            phx-value-challenge_id={challenge.id}
            phx-target={@myself}
            role="menuitem"
            class={[
              "w-full text-left px-4 py-3 text-sm transition-colors",
              if(@selected_challenge_id == challenge.id, do: "bg-brand-50 text-brand-900", else: "text-ui-700 hover:bg-ui-50 hover:text-ui-900")
            ]}
          >
            <div class="flex items-start justify-between gap-3">
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2">
                  <span class="font-semibold truncate"><%= challenge.name %></span>
                  <.challenge_badge challenge={challenge} />
                </div>
                <div class="mt-1 text-xs text-ui-600">
                  <%= format_date_range(challenge.start_date, challenge.end_date) %>
                </div>
              </div>
              <.icon
                :if={@selected_challenge_id == challenge.id}
                name="hero-check"
                class="w-5 h-5 text-brand-600 flex-shrink-0"
              />
            </div>
          </button>

          <div :if={@challenges == []} class="px-4 py-6 text-center text-sm text-ui-600">
            No challenges available
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private helper functions

  defp selected_challenge_name(challenges, selected_id) do
    case Enum.find(challenges, &(&1.id == selected_id)) do
      nil -> "Select a challenge"
      challenge -> challenge.name
    end
  end

  defp get_default_challenge_id([]), do: nil
  defp get_default_challenge_id([first | _]), do: first.id

  defp format_date_range(start_date, end_date) do
    start_str = Calendar.strftime(start_date, "%b %d, %Y")
    end_str = Calendar.strftime(end_date, "%b %d, %Y")
    "#{start_str} - #{end_str}"
  end

  attr :challenge, :map, required: true

  defp challenge_badge(assigns) do
    ~H"""
    <span
      :if={@challenge.is_active}
      class="inline-flex items-center rounded-full bg-brand-100 px-2 py-0.5 text-xs font-medium text-brand-800 ring-1 ring-inset ring-brand-600/20"
    >
      Active
    </span>
    """
  end
end
