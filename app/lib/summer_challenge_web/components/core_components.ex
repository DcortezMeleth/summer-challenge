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
    <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 bg-blue-600 text-white px-4 py-2 rounded-md z-50">
      Skip to main content
    </a>
    <main id="main-content" class="container mx-auto px-4 py-8 max-w-4xl" role="main">
      <%= render_slot(@inner_block) %>
    </main>
    """
  end

  @doc """
  Sport switch component for toggling between running and cycling leaderboards.
  """
  attr :tabs, :list, required: true

  def sport_switch(assigns) do
    ~H"""
    <nav aria-label="Sport selection" class="mb-6" role="tablist">
      <div class="flex space-x-1 bg-gray-100 p-1 rounded-lg w-fit">
        <.link
          :for={tab <- @tabs}
          patch={tab.to}
          role="tab"
          tabindex={if(tab.active, do: "0", else: "0")}
          aria-selected={if(tab.active, do: "true", else: "false")}
          aria-controls={"#{tab.id}-panel"}
          class={[
            "px-4 py-2 rounded-md text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
            if(tab.active, do: "bg-white text-gray-900 shadow-sm", else: "text-gray-500 hover:text-gray-700 hover:bg-gray-200")
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
    <p class="text-sm text-gray-600 mb-4">
      <%= @last_sync_label %>
    </p>
    """
  end

  @doc """
  Error banner component for displaying error messages.
  """
  attr :error_message, :string, required: true

  def error_banner(assigns) do
    ~H"""
    <div class="bg-red-50 border border-red-200 rounded-md p-4 mb-4" role="alert" aria-live="assertive">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm text-red-800">
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
    <div class="bg-white shadow rounded-lg overflow-hidden" role="region" aria-labelledby="leaderboard-heading">
      <table class="min-w-full divide-y divide-gray-200" role="table" aria-label={@sport_label <> " Leaderboard"}>
        <caption id="leaderboard-heading" class="text-lg font-medium text-gray-900 py-4 px-6 text-left bg-gray-50">
          <%= @sport_label %> Leaderboard
        </caption>
        <thead class="bg-gray-50">
          <tr role="row">
            <th scope="col" role="columnheader" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Rank
            </th>
            <th scope="col" role="columnheader" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Name
            </th>
            <th scope="col" role="columnheader" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Team
            </th>
            <th scope="col" role="columnheader" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Distance
            </th>
            <th scope="col" role="columnheader" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Time
            </th>
            <th scope="col" role="columnheader" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Elevation
            </th>
            <th scope="col" role="columnheader" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Activities
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200" role="rowgroup">
          <%= for row <- @rows do %>
            <.leaderboard_row row={row} />
          <% end %>
        </tbody>
      </table>

      <div :if={@rows == []} class="text-center py-12 px-6" role="status" aria-live="polite">
        <p class="text-gray-500 text-sm">
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
    <tr role="row">
      <td role="gridcell" class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
        <%= @row.rank %>
      </td>
      <td role="gridcell" class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
        <div class="flex items-center">
          <span><%= @row.display_name %></span>
          <.joined_late_badge :if={@row.joined_late} joined_late={@row.joined_late} />
        </div>
      </td>
      <td role="gridcell" class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        <%= @row.team_name %>
      </td>
      <td role="gridcell" class="px-6 py-4 whitespace-nowrap text-sm text-gray-900" aria-label="Distance covered">
        <%= @row.distance_label %>
      </td>
      <td role="gridcell" class="px-6 py-4 whitespace-nowrap text-sm text-gray-900" aria-label="Moving time">
        <%= @row.moving_time_label %>
      </td>
      <td role="gridcell" class="px-6 py-4 whitespace-nowrap text-sm text-gray-900" aria-label="Elevation gain">
        <%= @row.elev_gain_label %>
      </td>
      <td role="gridcell" class="px-6 py-4 whitespace-nowrap text-sm text-gray-900" aria-label="Number of activities">
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
      class="ml-2 inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800"
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
