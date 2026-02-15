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

  def icon(%{name: "hero-calendar"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
    </svg>
    """
  end

  def icon(%{name: "hero-chevron-down"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
    </svg>
    """
  end

  def icon(%{name: "hero-chevron-up"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 15.75 7.5-7.5 7.5 7.5" />
    </svg>
    """
  end

  def icon(%{name: "hero-check"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
    </svg>
    """
  end

  def icon(%{name: "hero-plus"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
    </svg>
    """
  end

  def icon(%{name: "hero-pencil"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10" />
    </svg>
    """
  end

  def icon(%{name: "hero-document-duplicate"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 0 1-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 0 1 1.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 0 0-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 0 1-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 0 0-3.375-3.375h-1.5a1.125 1.125 0 0 1-1.125-1.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H9.75" />
    </svg>
    """
  end

  def icon(%{name: "hero-archive-box"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
    </svg>
    """
  end

  def icon(%{name: "hero-trash"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
    </svg>
    """
  end

  def icon(%{name: "hero-clock"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
    </svg>
    """
  end

  def icon(%{name: "hero-inbox"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="m2.25 13.5 8.5 6.5L19.25 13.5M2.25 8.25l9.9-6.7c.6-.4 1.4-.4 1.9 0l9.9 6.7M2.25 13.5V19.5a.75.75 0 0 0 .75.75h18a.75.75 0 0 0 .75-.75v-6l-9.7 6.4c-.6.4-1.4.4-1.9 0l-9.7-6.4ZM2.25 8.25v5.25m0-5.25h19.5" />
    </svg>
    """
  end

  def icon(%{name: "hero-exclamation-triangle"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" />
    </svg>
    """
  end

  def icon(%{name: "hero-trophy"} = assigns) do
    ~H"""
    <svg class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 18.75h-9m9 0a3 3 0 0 1 3 3h-15a3 3 0 0 1 3-3m9 0v-3.375c0-.621-.503-1.125-1.125-1.125h-.871M7.5 18.75v-3.375c0-.621.504-1.125 1.125-1.125h.872m5.007 0H9.497m5.007 0a7.454 7.454 0 0 1-.982-3.172M9.497 14.25a7.454 7.454 0 0 0 .981-3.172M5.25 4.236c-.982.143-1.954.317-2.916.52A6.003 6.003 0 0 0 7.73 9.728M5.25 4.236V4.5c0 2.108.966 3.99 2.48 5.228M5.25 4.236V2.721C7.456 2.41 9.71 2.25 12 2.25c2.291 0 4.545.16 6.75.47v1.516M7.73 9.728a6.726 6.726 0 0 0 2.748 1.35m8.272-6.842V4.5c0 2.108-.966 3.99-2.48 5.228m2.48-5.492a46.32 46.32 0 0 1 2.916.52 6.003 6.003 0 0 1-5.395 4.972m0 0a6.726 6.726 0 0 1-2.749 1.35m0 0a6.772 6.772 0 0 1-3.044 0" />
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
  slot :top_bar
  slot :challenge_selector

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
      <div class="bg-brand-900 w-full shadow-sm">
        <div class="mx-auto max-w-5xl px-4">
          <%= render_slot(@top_bar) %>
        </div>
      </div>
      <div class="mx-auto max-w-5xl px-4 py-10">
        <header class="mb-8">
          <div class="flex items-start justify-between gap-4">
            <div class="flex-1">
              <p class="text-xs font-semibold tracking-widest text-brand-700 uppercase">
                Summer Challenge
              </p>
              <h1 class="mt-2 text-3xl font-bold tracking-tight text-ui-900">
                Leaderboards
              </h1>
              <p class="mt-2 text-sm text-ui-700 max-w-prose">
                Outdoor-only totals for running and cycling. Compete hard, move smart.
              </p>
            </div>
            <div :if={@challenge_selector != []} class="flex-shrink-0 min-w-[20rem]">
              <%= render_slot(@challenge_selector) %>
            </div>
          </div>
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
    <div class="bg-rose-50 border border-rose-200 rounded-xl p-4 mb-6 shadow-sport" role="alert" aria-live="assertive">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-rose-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm text-rose-800 font-medium">
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
        <span class="font-semibold"><%= @row.display_name %></span>
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
  Onboarding shell component - layout wrapper for onboarding pages.

  Provides centered layout with consistent spacing for onboarding flow.
  """
  slot :inner_block, required: true

  def onboarding_shell(assigns) do
    ~H"""
    <main role="main" class="flex min-h-screen items-center justify-center bg-ui-50 py-10">
      <section class="w-full max-w-lg px-4">
        <%= render_slot(@inner_block) %>
      </section>
    </main>
    """
  end

  @doc """
  Onboarding card component - styled container for onboarding content.

  Provides a clean card UI with appropriate styling for the onboarding flow.
  """
  slot :inner_block, required: true

  def onboarding_card(assigns) do
    ~H"""
    <div class="rounded-2xl bg-white/90 ring-1 ring-ui-200 shadow-sport p-6">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Onboarding header component - primary copy for the onboarding flow.

  Shows the main heading and helper text for the onboarding process.
  """
  def onboarding_header(assigns) do
    ~H"""
    <div class="text-center mb-6">
      <h1 class="text-2xl font-bold text-ui-900 mb-2">
        You are joining the challenge
      </h1>
      <p class="text-ui-600">
        Choose a name that will appear on the public leaderboard.
      </p>
    </div>
    """
  end

  @doc """
  Display name form component - collects and validates the user's display name.

  Handles form submission, validation, and error display for the display name input.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :saving?, :boolean, required: true
  attr :submit_label, :string, default: "Continue"
  attr :focus_field, :atom, default: nil

  def display_name_form(assigns) do
    ~H"""
    <div class="mb-6">
      <.form for={@form} id="onboarding-form" phx-change="validate" phx-submit="submit" class="space-y-4">
        <div>
          <.input
            type="text"
            field={@form[:display_name]}
            placeholder="Enter your display name"
            required
            disabled={@saving?}
            class="w-full"
            phx-mounted={@focus_field == :display_name && Phoenix.LiveView.JS.focus()}
          />
        </div>

        <.button
          type="submit"
          disabled={@saving?}
          loading?={@saving?}
          class="w-full"
        >
          <%= if @saving?, do: "Setting up...", else: @submit_label %>
        </.button>
      </.form>
    </div>
    """
  end

  @doc """
  Inline error component - displays field-level validation errors.

  Shows error messages below form fields with consistent styling.
  """
  attr :messages, :list, required: true

  def error(assigns) do
    ~H"""
    <p :for={msg <- @messages} class="mt-1 text-sm text-rose-600">
      <%= msg %>
    </p>
    """
  end

  @doc """
  Primary button component - styled button for primary actions.

  Provides consistent styling for primary buttons with loading states.
  """
  attr :type, :string, default: "button"
  attr :disabled, :boolean, default: false
  attr :loading?, :boolean, default: false
  attr :class, :string, default: ""
  attr :rest, :global

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled || @loading?}
      class={[
        "inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm",
        "text-white bg-brand-700 hover:bg-brand-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-500",
        "disabled:bg-ui-400 disabled:cursor-not-allowed",
        @loading? && "cursor-wait",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox color date datetime-local email file hidden month number password
                                           range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                                  multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error/1))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-ui-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-ui-300 text-ui-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error messages={@errors} />
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-ui-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-ui-400 focus:outline-none focus:ring-4 focus:ring-ui-800/5"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error messages={@errors} />
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-ui-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-ui-300 phx-no-feedback:focus:border-ui-400",
          @errors == [] && "border-ui-300 focus:border-ui-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error messages={@errors} />
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-md border border-ui-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-ui-400 focus:outline-none focus:ring-4 focus:ring-ui-800/5",
          "phx-no-feedback:border-ui-300 phx-no-feedback:focus:border-ui-400",
          @errors == [] && "border-ui-300 focus:border-ui-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error messages={@errors} />
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-ui-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Authentication section component - shows auth UI based on user state.

  Displays sign-in button for unauthenticated users, user menu for authenticated users.
  """
  attr :current_scope, :map, required: true
  attr :current_user, :any, default: nil

  def auth_section(assigns) do
    ~H"""
    <div class="flex items-center justify-start space-x-4 py-3">
      <%= if @current_scope.authenticated? do %>
        <!-- User menu with admin link if applicable -->
        <div class="flex items-center space-x-4">
          <div class="text-sm text-brand-50 font-medium">
            Welcome, <%= @current_user.display_name %>!
          </div>
          <.link
            navigate="/leaderboard/running_outdoor"
            class="text-xs text-brand-200 hover:text-white underline transition-colors"
          >
            Leaderboard
          </.link>
          <.link
            navigate="/milestone"
            class="text-xs text-brand-200 hover:text-white underline transition-colors"
          >
            Milestone
          </.link>
          <.link
            navigate="/my/activities"
            class="text-xs text-brand-200 hover:text-white underline transition-colors"
          >
            My Activities
          </.link>
          <%= if @current_scope.is_admin do %>
            <.link
              navigate="/admin/challenges"
              class="text-xs text-brand-200 hover:text-white underline transition-colors"
            >
              Admin
            </.link>
          <% end %>
          <.link
            href="/auth/logout"
            method="delete"
            class="text-xs text-brand-200 hover:text-white underline transition-colors"
          >
            Sign out
          </.link>
        </div>
      <% else %>
        <.sign_in_button />
      <% end %>
    </div>
    """
  end

  @doc """
  Sign in with Strava button - initiates OAuth flow.

  Strava-branded button that redirects to OAuth authorization.
  """
  def sign_in_button(assigns) do
    ~H"""
    <a href="/auth/strava" class="hover:opacity-90 transition-opacity">
      <img
        src="/images/btn_strava_connect_with_orange.svg"
        alt="Connect with Strava"
        class="h-10 w-auto"
      />
    </a>
    """
  end

  @doc """
  Terms and privacy notice component - displays legal notice.

  Shows terms/privacy links with implied acceptance messaging.
  """
  attr :terms_href, :string, required: true
  attr :privacy_href, :string, required: true

  def terms_privacy_notice(assigns) do
    ~H"""
    <div class="text-center text-sm text-ui-500">
      <p>
        By continuing you agree to our
        <.link navigate={@terms_href} class="text-brand-700 hover:text-brand-900 underline">
          Terms
        </.link>
        and
        <.link navigate={@privacy_href} class="text-brand-700 hover:text-brand-900 underline">
          Privacy Policy
        </.link>.
      </p>
    </div>
    """
  end
end
