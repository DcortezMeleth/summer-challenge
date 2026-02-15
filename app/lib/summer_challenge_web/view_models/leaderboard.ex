defmodule SummerChallengeWeb.ViewModels.Leaderboard do
  @moduledoc """
  View models for leaderboard-related UI components.

  These structs represent the data structures optimized for rendering
  leaderboard views, transforming DTOs into UI-ready formats.
  """

  @typedoc "Navigation tab for switching between sports"
  @type sport_tab :: %{
          id: atom(),
          label: String.t(),
          to: String.t(),
          active: boolean()
        }

  @typedoc "Individual leaderboard entry for display"
  @type row :: %{
          rank: non_neg_integer(),
          display_name: String.t(),
          team_name: String.t(),
          distance_label: String.t(),
          moving_time_label: String.t(),
          elev_gain_label: String.t(),
          activity_count_label: String.t()
        }

  @typedoc "Complete page data for leaderboard rendering"
  @type page :: %{
          sport: atom(),
          sport_label: String.t(),
          tabs: [sport_tab()],
          last_sync_label: String.t(),
          rows: [row()],
          empty?: boolean(),
          empty_message: String.t(),
          error_message: String.t() | nil
        }

  defmodule Page do
    @moduledoc false
    defstruct [
      :sport,
      :sport_label,
      :tabs,
      :last_sync_label,
      :rows,
      :empty?,
      :empty_message,
      :error_message
    ]
  end

  @doc """
  Creates a sport tab view model.

  ## Examples

      iex> tab(:running, "/leaderboard/running", true)
      %{id: :running, label: "Running", to: "/leaderboard/running", active: true}
  """
  @spec tab(atom(), String.t(), boolean()) :: sport_tab()
  def tab(id, to, active?) do
    %{
      id: id,
      label: sport_label(id),
      to: to,
      active: active?
    }
  end

  defp sport_label(:running_outdoor), do: "Running (Outdoor)"
  defp sport_label(:cycling_outdoor), do: "Cycling (Outdoor)"
  defp sport_label(:running_virtual), do: "Running (Virtual)"
  defp sport_label(:cycling_virtual), do: "Cycling (Virtual)"

  defp sport_label(sport),
    do:
      sport
      |> to_string()
      |> String.split("_")
      |> Enum.map_join(" ", &String.capitalize/1)

  @doc """
  Creates a leaderboard row view model from a DTO entry.

  ## Examples

      iex> dto = %{rank: 1, user: %{display_name: "Alice", team_name: "Team A"}, totals: %{distance_m: 10000, moving_time_s: 3600, elev_gain_m: 100, activity_count: 5}}
      iex> row(dto)
      %{rank: 1, display_name: "Alice", team_name: "Team A", ...}
  """
  @spec row(map()) :: row()
  def row(%{
        rank: rank,
        user: %{display_name: display_name, team_name: team_name},
        totals: %{
          distance_m: distance,
          moving_time_s: time,
          elev_gain_m: elevation,
          activity_count: count
        }
      }) do
    %{
      rank: rank,
      display_name: display_name,
      team_name: normalize_team_name(team_name),
      distance_label: SummerChallengeWeb.Formatters.format_km(distance),
      moving_time_label: SummerChallengeWeb.Formatters.format_duration(time),
      elev_gain_label: SummerChallengeWeb.Formatters.format_meters(elevation),
      activity_count_label: Integer.to_string(count)
    }
  end

  defp normalize_team_name(team_name) when is_binary(team_name) do
    if String.trim(team_name) == "", do: "—", else: team_name
  end

  defp normalize_team_name(_), do: "—"

  @doc """
  Creates a complete leaderboard page view model.

  ## Examples

      iex> page(:running, "Running", tabs, "Last sync: 12:00", rows, nil)
      %{sport: :running, sport_label: "Running", tabs: tabs, ...}
  """
  @spec page(
          atom(),
          String.t(),
          [sport_tab()],
          String.t(),
          [row()],
          String.t() | nil
        ) :: page()
  def page(sport, sport_label, tabs, last_sync_label, rows, error_message) do
    %{
      sport: sport,
      sport_label: sport_label,
      tabs: tabs,
      last_sync_label: last_sync_label,
      rows: rows,
      empty?: rows == [],
      empty_message: "No results yet; check back after the first sync.",
      error_message: error_message
    }
  end

  @doc """
  Creates an error page view model.

  ## Examples

      iex> error_page(:running_outdoor, "Error loading data")
      %{sport: :running_outdoor, sport_label: "Running (Outdoor)", rows: [], error_message: "Error loading data", ...}
  """
  @spec error_page(atom(), String.t()) :: page()
  def error_page(sport, error_message) do
    sport_label = sport_label(sport)

    tabs = [
      tab(:running_outdoor, "/leaderboard/running_outdoor", sport == :running_outdoor),
      tab(:cycling_outdoor, "/leaderboard/cycling_outdoor", sport == :cycling_outdoor)
    ]

    page(sport, sport_label, tabs, "Last sync: not yet completed", [], error_message)
  end
end
