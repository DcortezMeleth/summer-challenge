defmodule SummerChallengeWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "app" layout is used as the default layout to render
  all LiveViews and controller views in your application.
  """
  use Phoenix.Component

  import SummerChallengeWeb.CoreComponents
  import SummerChallengeWeb.Gettext

  # Routes generation with the ~p sigil
  use Phoenix.VerifiedRoutes,
    endpoint: SummerChallengeWeb.Endpoint,
    router: SummerChallengeWeb.Router,
    statics: SummerChallengeWeb.static_paths()

  # Shortcut for generating JS commands
  alias Phoenix.LiveView.JS

  @doc """
  The app layout renders the main application structure with
  navigation and flash messages.
  """
  def app(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="[scrollbar-gutter:stable]">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <.live_title suffix=" · Phoenix Framework">
          <%= assigns[:page_title] || "Summer Challenge" %>
        </.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static src={~p"/assets/app.js"}>
        </script>
      </head>
      <body class="min-h-screen bg-ui-50 text-ui-900 antialiased">
        <.flash_group flash={@flash} />
        <%= @inner_content %>
      </body>
    </html>
    """
  end

  @doc """
  Renders the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages to display"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash kind={:warning} title="Warning!" flash={@flash} />
    """
  end

  @doc """
  Shows the flash.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} title="Welcome!" flash={@flash} />
  """
  attr :kind, :atom, values: [:info, :error, :warning], doc: "used for styling and flash lookup"
  attr :title, :string, default: nil, doc: "the flash title, defaults to the :kind"
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash(assigns) do
    assigns = assign_new(assigns, :title, fn -> Phoenix.Naming.humanize(assigns.kind) end)

    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      id={"flash-#{@kind}"}
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-xl p-3 ring-1 bg-white shadow-sport",
        if(@kind == :info, do: "ring-brand-200", else: "ring-ui-200")
      ]}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.remove_class("fade-in-scale", transition: "fade-out-scale")}
      phx-hook="Phoenix.Flash"
      role="alert"
    >
      <p class="flex items-center gap-1.5 text-sm font-semibold leading-6 text-ui-900">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4 text-brand-700" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4 text-red-600" />
        <.icon :if={@kind == :warning} name="hero-exclamation-triangle-mini" class="h-4 w-4 text-amber-500" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5 text-ui-700"><%= msg %></p>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end


  @doc """
  Generates tag for inlined form input errors.
  """
  def error(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns = assign(assigns, :errors, Enum.map(field.errors, &translate_error(&1)))

    ~H"""
    <.error :for={msg <- @errors}><%= msg %></.error>
    """
  end

  def error(%{} = assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Translates an error message.
  """
  def translate_error({msg, opts}) do
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
