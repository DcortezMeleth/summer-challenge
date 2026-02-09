defmodule SummerChallengeWeb.OnboardingLive do
  @moduledoc """
  LiveView for the onboarding flow - first login step for new users.

  This module handles the onboarding process where new users set their display name
  and complete the initial setup before joining the challenge. It validates input,
  persists the onboarding completion, and navigates to a safe return destination.
  """

  use SummerChallengeWeb, :live

  alias SummerChallenge.Accounts
  alias SummerChallengeWeb.ViewModels.Onboarding, as: OnboardingVM
  alias SummerChallenge.Model.Types

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if Accounts.user_onboarded?(current_user) do
      # User is already onboarded, redirect to leaderboard
      {:ok, push_navigate(socket, to: "/leaderboard/running")}
    else
      # Initialize onboarding form
      changeset = build_initial_changeset(current_user)
      page = OnboardingVM.build_page(changeset, nil, nil)

      socket =
        socket
        |> assign(:page, page)
        |> assign(:saving?, false)

      {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    return_to = OnboardingVM.sanitize_return_to(params["return_to"])

    socket =
      socket
      |> assign(:return_to, return_to)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"onboarding" => params}, socket) do
    changeset = validate_display_name(params)
    page = OnboardingVM.build_page(changeset, nil, nil)

    {:noreply, assign(socket, :page, page)}
  end

  @impl true
  def handle_event("submit", %{"onboarding" => params}, socket) do
    socket = assign(socket, :saving?, true)

    changeset = validate_display_name(params)

    if changeset.valid? do
      # Extract validated display name
      display_name = Ecto.Changeset.get_field(changeset, :display_name)

      # Call domain API to complete onboarding
      case Accounts.complete_onboarding(socket.assigns.current_user.id, display_name) do
        {:ok, updated_user} ->
          # Update socket with new user data and navigate to safe return destination
          return_path = socket.assigns.return_to || "/leaderboard/running"

          socket =
            socket
            |> assign(:current_user, updated_user)

          {:noreply, push_navigate(socket, to: return_path)}

        {:error, %Ecto.Changeset{} = error_changeset} ->
          # Validation error from domain layer
          page =
            OnboardingVM.build_page(
              error_changeset,
              "Unable to complete onboarding. Please check your input.",
              :display_name
            )

          socket =
            socket
            |> assign(:saving?, false)
            |> assign(:page, page)

          {:noreply, socket}

        {:error, :user_not_found} ->
          # User not found - redirect to leaderboard with error
          socket =
            socket
            |> assign(:saving?, false)
            |> put_flash(:error, "Session expired. Please sign in again.")

          {:noreply, push_navigate(socket, to: "/leaderboard/running")}

        {:error, reason} ->
          # Unexpected error
          page =
            OnboardingVM.build_page(
              changeset,
              "An unexpected error occurred. Please try again.",
              nil
            )

          socket =
            socket
            |> assign(:saving?, false)
            |> assign(:page, page)
            |> put_flash(:error, "Failed to complete onboarding: #{inspect(reason)}")

          {:noreply, socket}
      end
    else
      # Client-side validation failed
      page = OnboardingVM.build_page(changeset, nil, :display_name)

      socket =
        socket
        |> assign(:saving?, false)
        |> assign(:page, page)

      {:noreply, socket}
    end
  end

  # Private functions

  @spec build_initial_changeset(Types.user_dto() | nil) :: Ecto.Changeset.t()
  defp build_initial_changeset(current_user) do
    # Create a simple changeset for display name validation
    data = %{display_name: (current_user && current_user.display_name) || ""}
    types = %{display_name: :string}

    {data, types}
    |> Ecto.Changeset.cast(%{}, [:display_name])
  end

  @spec validate_display_name(map()) :: Ecto.Changeset.t()
  defp validate_display_name(params) do
    data = %{display_name: ""}
    types = %{display_name: :string}

    {data, types}
    |> Ecto.Changeset.cast(params, [:display_name])
    |> Ecto.Changeset.validate_required([:display_name])
    |> Ecto.Changeset.validate_length(:display_name, min: 1, max: 80)
    |> Ecto.Changeset.validate_change(:display_name, fn :display_name, value ->
      trimmed = String.trim(value)

      if trimmed == "" do
        [display_name: "Display name cannot be blank"]
      else
        []
      end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.app_shell>
      <.onboarding_shell>
        <.onboarding_card>
          <.onboarding_header />

          <.display_name_form
            form={@page.form}
            saving?={@saving?}
            focus_field={@page.form.focus_field}
          />

          <.terms_privacy_notice
            terms_href="/terms"
            privacy_href="/privacy"
          />
        </.onboarding_card>
      </.onboarding_shell>
    </.app_shell>
    """
  end
end
