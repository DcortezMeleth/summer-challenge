defmodule SummerChallengeWeb.ViewModels.Onboarding do
  @moduledoc """
  View models and helper functions for the onboarding flow.

  This module provides types and functions for building onboarding page data,
  validating return paths, and managing the onboarding form state.
  """

  @typedoc "Safe return path after onboarding completion (allowlisted)."
  @type safe_return_to_path :: String.t()

  @typedoc "Render-ready data for the Onboarding page."
  @type onboarding_page_vm :: %{
          page_title: String.t(),
          return_to: safe_return_to_path(),
          form: onboarding_form_vm(),
          terms: terms_links_vm()
        }

  @typedoc "State for the onboarding form."
  @type onboarding_form_vm :: %{
          form: Phoenix.HTML.Form.t(),
          saving?: boolean(),
          submit_error: String.t() | nil,
          focus_field: :display_name | nil
        }

  @typedoc "Configurable links for the Terms/Privacy notice."
  @type terms_links_vm :: %{
          terms_href: String.t(),
          privacy_href: String.t()
        }

  @allowed_return_paths [
    "/leaderboard/running",
    "/leaderboard/cycling",
    "/milestone",
    "/my/activities",
    "/teams",
    "/settings",
    "/admin"
  ]

  @doc """
  Builds the complete onboarding page view model.

  ## Parameters
  - `changeset`: Ecto changeset for form validation
  - `submit_error`: Optional error message for submission failures
  - `focus_field`: Field to focus after render (optional)

  ## Returns
  - `onboarding_page_vm()`
  """
  @spec build_page(Ecto.Changeset.t(), String.t() | nil, :display_name | nil) :: onboarding_page_vm()
  def build_page(changeset, submit_error, focus_field \\ nil) do
    form = Phoenix.Component.to_form(changeset, as: :onboarding)

    %{
      page_title: "Join the Challenge",
      return_to: "/leaderboard/running", # Default fallback
      form: %{
        form: form,
        saving?: false,
        submit_error: submit_error,
        focus_field: focus_field
      },
      terms: %{
        terms_href: "/terms", # TODO: Update when terms page exists
        privacy_href: "/privacy" # TODO: Update when privacy page exists
      }
    }
  end

  @doc """
  Sanitizes and validates a return_to parameter to prevent open redirects.

  Only allows relative paths starting with "/" and rejects any path containing
  "//" (protocol-relative URLs) or not in the allowlist.

  ## Parameters
  - `return_to`: Raw return path from query params

  ## Returns
  - Safe return path or default fallback
  """
  @spec sanitize_return_to(String.t() | nil) :: safe_return_to_path()
  def sanitize_return_to(nil), do: "/leaderboard/running"
  def sanitize_return_to(return_to) when is_binary(return_to) do
    return_to = URI.decode(return_to)

    cond do
      # Must be relative path starting with "/"
      not String.starts_with?(return_to, "/") ->
        "/leaderboard/running"

      # Reject protocol-relative URLs
      String.contains?(return_to, "//") ->
        "/leaderboard/running"

      # Check against allowlist
      return_to in @allowed_return_paths ->
        return_to

      # Default fallback
      true ->
        "/leaderboard/running"
    end
  end

  @doc """
  Updates the form view model with saving state and focus field.

  ## Parameters
  - `form_vm`: Current form view model
  - `saving?`: Whether a save operation is in progress
  - `focus_field`: Field to focus after render (optional)

  ## Returns
  - Updated `onboarding_form_vm()`
  """
  @spec update_form_state(onboarding_form_vm(), boolean(), :display_name | nil) :: onboarding_form_vm()
  def update_form_state(form_vm, saving?, focus_field \\ nil) do
    %{form_vm | saving?: saving?, focus_field: focus_field}
  end
end
