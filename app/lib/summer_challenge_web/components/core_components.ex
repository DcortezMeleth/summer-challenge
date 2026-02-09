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

  @doc """
  Onboarding shell component - layout wrapper for onboarding pages.

  Provides centered layout with consistent spacing for onboarding flow.
  """
  slot :inner_block, required: true

  def onboarding_shell(assigns) do
    ~H"""
    <main role="main" class="flex min-h-screen items-center justify-center bg-gray-50 py-10">
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
    <div class="rounded-2xl bg-white/90 ring-1 ring-gray-200 shadow-sport p-6">
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
      <h1 class="text-2xl font-bold text-gray-900 mb-2">
        You are joining the challenge
      </h1>
      <p class="text-gray-600">
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
      <.form for={@form} phx-change="validate" phx-submit="submit" class="space-y-4">
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
          <.error messages={Enum.map(@form[:display_name].errors, &translate_error/1)} />
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
    <p :for={msg <- @messages} class="mt-1 text-sm text-red-600">
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
        "text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
        "disabled:bg-gray-400 disabled:cursor-not-allowed",
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
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
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
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-zinc-400 focus:outline-none focus:ring-4 focus:ring-zinc-800/5"
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
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
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
          "mt-2 block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm shadow-sm focus:border-zinc-400 focus:outline-none focus:ring-4 focus:ring-zinc-800/5",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
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
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
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
    <div class="flex items-center justify-end space-x-4 py-4">
      <%= if @current_scope.authenticated? do %>
        <!-- Future: User menu with profile options -->
        <div class="text-sm text-gray-700">
          Welcome, <%= @current_user.display_name %>!
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
    <a
      href="/auth/strava"
      class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-orange-500 hover:bg-orange-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500 transition-colors"
    >
      <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
        <path d="M15.387 17.944l-2.089-4.116h-3.065L15.387 24l5.15-10.172h-3.066m-7.008-5.599l2.836 5.598h4.172L10.463 0l-7.3 14.401h4.169"/>
      </svg>
      Sign in with Strava
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
    <div class="text-center text-sm text-gray-500">
      <p>
        By continuing you agree to our
        <.link navigate={@terms_href} class="text-blue-600 hover:text-blue-800 underline">
          Terms
        </.link>
        and
        <.link navigate={@privacy_href} class="text-blue-600 hover:text-blue-800 underline">
          Privacy Policy
        </.link>.
      </p>
    </div>
    """
  end
end
