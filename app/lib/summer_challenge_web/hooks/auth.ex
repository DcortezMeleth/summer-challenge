defmodule SummerChallengeWeb.Hooks.Auth do
  @moduledoc """
  Authentication hook for LiveView.

  This hook handles loading the current user from session and ensuring
  authenticated routes are properly protected. It assigns current_user
  and current_scope to the socket for use in templates and event handlers.
  """

  import Phoenix.Component
  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  alias SummerChallenge.Accounts

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:require_authenticated_user, _params, %{"user_id" => user_id}, socket) do
    require Logger
    Logger.info("Auth hook: user_id from session: #{inspect(user_id)}")

    case Accounts.get_user(user_id) do
      nil ->
        Logger.error("Auth hook: User not found for user_id: #{inspect(user_id)}")
        # User not found, redirect to leaderboard with error
        socket =
          socket
          |> put_flash(:error, "Session expired. Please sign in again.")
          |> redirect(to: "/leaderboard/running")

        {:halt, socket}

      user ->
        Logger.info("Auth hook: User found: #{inspect(user.id)}")
        # User found, assign to socket
        assign(socket,
          current_user: user,
          current_scope: %{authenticated?: true, user_id: user.id}
        )

        {:cont, socket}
    end
  end

  def on_mount(:require_authenticated_user, _params, _session, socket) do
    # No user_id in session, redirect to leaderboard
    socket =
      socket
      |> put_flash(:error, "Please sign in to continue.")
      |> redirect(to: "/leaderboard/running")

    {:halt, socket}
  end

  @doc """
  Mount hook for optional authentication.

  For routes that work with or without authentication, this hook:
  - Loads the current user from session if present
  - Assigns current_user and current_scope appropriately
  - Does not redirect if user is not authenticated

  ## Parameters
  - `params`: LiveView params
  - `session`: Session data containing user_id
  - `socket`: LiveView socket

  ## Returns
  - `{:cont, socket}` always
  """
  @spec on_mount(:optional, map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:optional, _params, %{"user_id" => user_id}, socket) do
    case Accounts.get_user(user_id) do
      nil ->
        # No valid user, assign empty auth context
        assign(socket, current_user: nil, current_scope: %{authenticated?: false, user_id: nil})

        {:cont, socket}

      user ->
        # User found, assign to socket
        assign(socket,
          current_user: user,
          current_scope: %{authenticated?: true, user_id: user.id}
        )

        {:cont, socket}
    end
  end

  def on_mount(:optional, _params, _session, socket) do
    # No user_id in session, assign empty auth context
    socket =
      socket
      |> assign(:current_user, nil)
      |> assign(:current_scope, %{authenticated?: false, user_id: nil})

    {:cont, socket}
  end
end
