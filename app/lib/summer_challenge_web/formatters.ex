defmodule SummerChallengeWeb.Formatters do
  @moduledoc """
  Formatting utilities for leaderboard display values.

  This module provides pure functions for formatting distances, durations,
  elevations, and timestamps for consistent display across the application.
  """

  @doc """
  Formats distance in meters to kilometers with one decimal place.

  ## Examples

      iex> format_km(1500)
      "1.5 km"

      iex> format_km(0)
      "0.0 km"
  """
  @spec format_km(non_neg_integer()) :: String.t()
  def format_km(distance_m) when is_integer(distance_m) and distance_m >= 0 do
    km = distance_m / 1000.0
    :io_lib.format("~.1f km", [km]) |> to_string()
  end

  @doc """
  Formats duration in seconds to HH:MM:SS format.

  ## Examples

      iex> format_duration(3661)
      "01:01:01"

      iex> format_duration(65)
      "00:01:05"

      iex> format_duration(3723)
      "01:02:03"
  """
  @spec format_duration(non_neg_integer()) :: String.t()
  def format_duration(seconds) when is_integer(seconds) and seconds >= 0 do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    remaining_seconds = rem(seconds, 60)

    :io_lib.format("~2..0B:~2..0B:~2..0B", [hours, minutes, remaining_seconds])
    |> to_string()
  end

  @doc """
  Formats elevation in meters with comma separators for thousands.

  ## Examples

      iex> format_meters(1234)
      "1,234 m"

      iex> format_meters(100)
      "100 m"

      iex> format_meters(0)
      "0 m"
  """
  @spec format_meters(non_neg_integer()) :: String.t()
  def format_meters(meters) when is_integer(meters) and meters >= 0 do
    # Format with thousands separator
    meters
    |> Integer.to_string()
    |> String.reverse()
    |> String.to_charlist()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
    |> Kernel.<>(" m")
  end

  @doc """
  Formats a DateTime to Warsaw timezone display string.

  ## Examples

      iex> format_warsaw_datetime(~U[2024-12-20 12:00:00Z])
      "Last sync: 2024-12-20 13:00 CET"

      iex> format_warsaw_datetime(nil)
      "Last sync: not yet completed"
  """
  @spec format_warsaw_datetime(DateTime.t() | nil) :: String.t()
  def format_warsaw_datetime(nil) do
    "Last sync: not yet completed"
  end

  def format_warsaw_datetime(datetime) do
    warsaw_tz = "Europe/Warsaw"

    case DateTime.shift_zone(datetime, warsaw_tz) do
      {:ok, warsaw_time} ->
        formatted = Calendar.strftime(warsaw_time, "%Y-%m-%d %H:%M %Z")
        "Last sync: #{formatted}"

      {:error, _} ->
        # Fallback to UTC if timezone conversion fails
        formatted = Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")
        "Last sync: #{formatted}"
    end
  end
end
