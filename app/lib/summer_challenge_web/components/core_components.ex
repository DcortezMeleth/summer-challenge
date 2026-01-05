defmodule SummerChallengeWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  @doc """
  Renders a [Hero Icon](https://heroicons.com).

  Hero icons come in three styles – outline (`:outline`), solid (`:solid`), and mini (`:mini`).

  You can customize the size and colors of the icons:

      <Icon.outline name="eye" class="w-4 h-4 text-blue-500" />
      <Icon.solid name="eye" class="w-4 h-4 text-blue-500" />
      <Icon.mini name="eye" class="w-4 h-4 text-blue-500" />

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-information-circle-mini"} = assigns) do
    ~H"""
    <svg class={@class} viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
      <path
        fill-rule="evenodd"
        d="M18 10a8 8 0 1 1-16 0 8 8 0 0 1 16 0ZM9 9a1 1 0 1 0 0-2 1 1 0 0 0 0 2Zm.75 6a.75.75 0 0 0 1.5 0V10a.75.75 0 0 0-1.5 0v5Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  def icon(%{name: "hero-exclamation-circle-mini"} = assigns) do
    ~H"""
    <svg class={@class} viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
      <path
        fill-rule="evenodd"
        d="M18 10a8 8 0 1 1-16 0 8 8 0 0 1 16 0Zm-8-4a.75.75 0 0 0-.75.75v4.5a.75.75 0 0 0 1.5 0v-4.5A.75.75 0 0 0 10 6Zm0 9a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  def icon(%{name: "hero-exclamation-triangle-mini"} = assigns) do
    ~H"""
    <svg class={@class} viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
      <path
        fill-rule="evenodd"
        d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l6.516 11.59c.75 1.334-.213 2.98-1.742 2.98H3.483c-1.53 0-2.493-1.646-1.743-2.98l6.517-11.59ZM11 14a1 1 0 1 1-2 0 1 1 0 0 1 2 0Zm-1-8a1 1 0 0 0-1 1v3a1 1 0 1 0 2 0V7a1 1 0 0 0-1-1Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  def icon(%{name: "hero-arrow-left-solid"} = assigns) do
    ~H"""
    <svg class={@class} viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
      <path
        fill-rule="evenodd"
        d="M17 10a.75.75 0 0 1-.75.75H6.56l3.22 3.22a.75.75 0 1 1-1.06 1.06l-4.5-4.5a.75.75 0 0 1 0-1.06l4.5-4.5a.75.75 0 0 1 1.06 1.06L6.56 9.25h9.69A.75.75 0 0 1 17 10Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  def icon(%{name: "hero-x-mark-solid"} = assigns) do
    ~H"""
    <svg class={@class} viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
      <path
        fill-rule="evenodd"
        d="M4.22 4.22a.75.75 0 0 1 1.06 0L10 8.94l4.72-4.72a.75.75 0 1 1 1.06 1.06L11.06 10l4.72 4.72a.75.75 0 1 1-1.06 1.06L10 11.06l-4.72 4.72a.75.75 0 0 1-1.06-1.06L8.94 10 4.22 5.28a.75.75 0 0 1 0-1.06Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  App shell component providing consistent page layout.
  """
  slot :inner_block, required: true

  def app_shell(assigns) do
    ~H"""
    <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 bg-brand-700 text-white px-4 py-2 rounded-md z-50">
      Skip to main content
    </a>
    <main
      id="main-content"
      class="min-h-screen bg-gradient-to-b from-brand-50 via-ui-50 to-ui-50"
      role="main"
    >
      <div class="mx-auto max-w-5xl px-4 py-10">
        <header class="mb-8">
          <p class="text-xs font-semibold tracking-widest text-brand-700 uppercase">
            Summer Challenge
          </p>
          <h1 class="mt-2 text-3xl font-bold tracking-tight text-ui-900">
            Leaderboards
          </h1>
          <p class="mt-2 text-sm text-ui-700 max-w-prose">
            Outdoor-only totals for running and cycling. Compete hard, move smart.
          </p>
        </header>

        <%= render_slot(@inner_block) %>
      </div>
    </main>
    """
  end

  @doc """
  Sport switch component for toggling between running and cycling leaderboards.
  """
  attr :tabs, :list, required: true

  def sport_switch(assigns) do
    ~H"""
    <nav aria-label="Sport selection" class="mb-6">
      <div class="inline-flex space-x-1 bg-white/80 p-1 rounded-xl w-fit ring-1 ring-ui-200 shadow-sport">
        <.link
          :for={tab <- @tabs}
          patch={tab.to}
          aria-current={if(tab.active, do: "page", else: nil)}
          class={[
            "px-5 py-2.5 rounded-lg text-sm font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-brand-600 focus:ring-offset-2 focus:ring-offset-ui-50",
            if(tab.active, do: "bg-brand-700 text-white shadow", else: "text-ui-700 hover:text-ui-900 hover:bg-ui-100")
          ]}
        >
          <%= tab.label %>
        </.link>
      </div>
    </nav>
    """
  end

  @doc """
  Sync status line component showing last sync timestamp.
  """
  attr :last_sync_label, :string, required: true

  def sync_status_line(assigns) do
    ~H"""
    <div class="mb-6 rounded-xl bg-white/80 ring-1 ring-ui-200 px-4 py-3 shadow-sport">
      <p class="text-sm text-ui-700">
        <span class="font-semibold text-ui-900">Last sync:</span>
        <span class="ml-1"><%= @last_sync_label %></span>
      </p>
    </div>
    """
  end

  @doc """
  Error banner component for displaying error messages.
  """
  attr :error_message, :string, required: true

  def error_banner(assigns) do
    ~H"""
    <div class="bg-red-50 border border-red-200 rounded-xl p-4 mb-6 shadow-sport" role="alert" aria-live="assertive">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm text-red-800 font-medium">
            <%= @error_message %>
          </p>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Leaderboard table component for displaying participant rankings.
  """
  attr :sport_label, :string, required: true
  attr :rows, :list, required: true
  attr :empty_message, :string, required: true

  def leaderboard_table(assigns) do
    ~H"""
    <div class="bg-white/90 shadow-sport rounded-2xl overflow-hidden ring-1 ring-ui-200" role="region" aria-labelledby="leaderboard-heading">
      <div class="overflow-x-auto">
        <table class="min-w-[52rem] w-full divide-y divide-ui-200" aria-label={@sport_label <> " Leaderboard"}>
          <caption id="leaderboard-heading" class="text-lg font-semibold text-white py-4 px-6 text-left bg-gradient-to-r from-brand-900 to-brand-700">
            <%= @sport_label %> Leaderboard
          </caption>
          <thead class="bg-ui-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
              Rank
            </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
              Name
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
          <%= for row <- @rows do %>
            <.leaderboard_row row={row} />
          <% end %>
        </tbody>
      </table>
      </div>

      <div :if={@rows == []} class="text-center py-12 px-6" role="status" aria-live="polite">
        <p class="text-ui-600 text-sm">
          <%= @empty_message %>
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Individual leaderboard row component.
  """
  attr :row, :map, required: true

  def leaderboard_row(assigns) do
    ~H"""
    <tr class="odd:bg-white even:bg-ui-50 hover:bg-brand-50/70 transition-colors">
      <td class="px-6 py-4 whitespace-nowrap text-sm tabular-nums">
        <span class={[
          "inline-flex items-center justify-center h-7 min-w-7 px-2 rounded-full font-bold",
          case @row.rank do
            1 -> "bg-brand-700 text-white"
            2 -> "bg-brand-100 text-brand-900 ring-1 ring-brand-200"
            3 -> "bg-ui-200 text-ui-900"
            _ -> "bg-ui-100 text-ui-900"
          end
        ]}>
          <%= @row.rank %>
        </span>
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-900">
        <div class="flex items-center">
          <span class="font-semibold"><%= @row.display_name %></span>
          <.joined_late_badge :if={@row.joined_late} joined_late={@row.joined_late} />
        </div>
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-700">
        <%= @row.team_name %>
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-900 text-right tabular-nums" aria-label="Distance covered">
        <%= @row.distance_label %>
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-900 text-right tabular-nums" aria-label="Moving time">
        <%= @row.moving_time_label %>
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-900 text-right tabular-nums" aria-label="Elevation gain">
        <%= @row.elev_gain_label %>
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-900 text-right tabular-nums" aria-label="Number of activities">
        <%= @row.activity_count_label %>
      </td>
    </tr>
    """
  end

  @doc """
  Badge component indicating late joiners.
  """
  attr :joined_late, :boolean, required: true

  def joined_late_badge(assigns) do
    ~H"""
    <span
      class="ml-2 inline-flex items-center px-2 py-0.5 rounded-lg text-xs font-semibold bg-brand-100 text-brand-900 ring-1 ring-brand-200"
      role="status"
      aria-label="Late joiner: Counting starts from authorization time when backfill is unavailable"
      title="Counting starts from authorization time when backfill is unavailable."
    >
      <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20" aria-hidden="true">
        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
      </svg>
      <span aria-hidden="true">Late Join</span>
    </span>
    """
  end
end
