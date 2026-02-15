defmodule SummerChallenge.Challenges do
  @moduledoc """
  Context for managing challenges.

  Provides functions for:
  - Listing and retrieving challenges
  - Creating, updating, and deleting challenges
  - Archiving challenges
  - Cloning challenges
  - Challenge selection logic
  """

  import Ecto.Query, warn: false

  alias SummerChallenge.Repo
  alias SummerChallenge.Model.Challenge

  @doc """
  Lists all challenges with optional filtering.

  ## Options
    * `:include_archived` - If true, includes archived challenges (default: false)
    * `:order_by` - Ordering strategy (default: :selector_order)
      - `:selector_order` - Active challenges first (by start_date desc), then inactive (by start_date desc)
      - `:start_date_asc` - Oldest first
      - `:start_date_desc` - Newest first
  """
  @spec list_challenges(keyword()) :: [Challenge.t()]
  def list_challenges(opts \\ []) do
    include_archived = Keyword.get(opts, :include_archived, false)
    order_by = Keyword.get(opts, :order_by, :selector_order)

    Challenge
    |> apply_archived_filter(include_archived)
    |> apply_ordering(order_by)
    |> Repo.all()
  end

  @doc """
  Returns challenges formatted for the selector dropdown.
  Active challenges are listed first, then inactive, both ordered by start_date descending.
  Archived challenges are excluded for non-admin users.
  """
  @spec list_challenges_for_selector(boolean()) :: [map()]
  def list_challenges_for_selector(include_archived \\ false) do
    list_challenges(include_archived: include_archived, order_by: :selector_order)
    |> Enum.map(&to_summary_dto/1)
  end

  @doc """
  Gets a single challenge by ID.
  """
  @spec get_challenge(Ecto.UUID.t()) :: {:ok, Challenge.t()} | {:error, :not_found}
  def get_challenge(id) do
    case Repo.get(Challenge, id) do
      nil -> {:error, :not_found}
      challenge -> {:ok, challenge}
    end
  end

  @doc """
  Gets a challenge by ID, raising if not found.
  """
  @spec get_challenge!(Ecto.UUID.t()) :: Challenge.t()
  def get_challenge!(id) do
    Repo.get!(Challenge, id)
  end

  @doc """
  Returns the default challenge based on selection rules:
  1. Active challenge with the latest start date
  2. If no active challenges, the most recent inactive challenge
  3. If no challenges exist, returns {:error, :no_challenges}
  """
  @spec get_default_challenge() :: {:ok, Challenge.t()} | {:error, :no_challenges}
  def get_default_challenge do
    now = DateTime.utc_now()

    # Try to find active challenge with latest start date
    active_challenge =
      Challenge
      |> where([c], c.status != "archived")
      |> where([c], c.start_date <= ^now and c.end_date >= ^now)
      |> order_by([c], desc: c.start_date)
      |> limit(1)
      |> Repo.one()

    case active_challenge do
      nil ->
        # No active challenges, get most recent inactive
        recent_challenge =
          Challenge
          |> where([c], c.status != "archived")
          |> order_by([c], desc: c.start_date)
          |> limit(1)
          |> Repo.one()

        case recent_challenge do
          nil -> {:error, :no_challenges}
          challenge -> {:ok, challenge}
        end

      challenge ->
        {:ok, challenge}
    end
  end

  @doc """
  Creates a new challenge.
  """
  @spec create_challenge(map()) :: {:ok, Challenge.t()} | {:error, Ecto.Changeset.t()}
  def create_challenge(attrs) do
    %Challenge{}
    |> Challenge.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a challenge.
  All fields can be updated at any time by admins.
  """
  @spec update_challenge(Challenge.t(), map()) ::
          {:ok, Challenge.t()} | {:error, Ecto.Changeset.t()}
  def update_challenge(%Challenge{} = challenge, attrs) do
    challenge
    |> Challenge.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a challenge.
  Can only delete challenges that have not started yet.
  """
  @spec delete_challenge(Challenge.t()) ::
          {:ok, Challenge.t()} | {:error, :cannot_delete | Ecto.Changeset.t()}
  def delete_challenge(%Challenge{} = challenge) do
    if Challenge.can_delete?(challenge) do
      Repo.delete(challenge)
    else
      {:error, :cannot_delete}
    end
  end

  @doc """
  Archives a challenge by setting its status to "archived".
  Can only archive challenges that have ended.
  """
  @spec archive_challenge(Challenge.t()) ::
          {:ok, Challenge.t()} | {:error, :cannot_archive | Ecto.Changeset.t()}
  def archive_challenge(%Challenge{} = challenge) do
    if Challenge.can_archive?(challenge) do
      update_challenge(challenge, %{status: "archived"})
    else
      {:error, :cannot_archive}
    end
  end

  @doc """
  Clones a challenge with new name and dates.
  Sport type configuration is copied from the source challenge.
  """
  @spec clone_challenge(Challenge.t(), map()) ::
          {:ok, Challenge.t()} | {:error, Ecto.Changeset.t()}
  def clone_challenge(%Challenge{} = source_challenge, attrs) do
    clone_attrs =
      Map.merge(
        %{
          name: attrs[:new_name] || "Copy of #{source_challenge.name}",
          start_date: attrs[:new_start_date],
          end_date: attrs[:new_end_date],
          allowed_sport_types: source_challenge.allowed_sport_types,
          status: "inactive"
        },
        Map.take(attrs, [:name, :start_date, :end_date])
      )

    create_challenge(clone_attrs)
  end

  @doc """
  Returns the sport type groups that are active for a challenge.
  """
  @spec get_sport_type_groups_for_challenge(Challenge.t()) :: [atom()]
  def get_sport_type_groups_for_challenge(%Challenge{} = challenge) do
    Challenge.active_sport_groups(challenge)
  end

  # Private helper functions

  defp apply_archived_filter(query, true), do: query

  defp apply_archived_filter(query, false) do
    where(query, [c], c.status != "archived")
  end

  defp apply_ordering(query, :selector_order) do
    now = DateTime.utc_now()

    query
    |> order_by([c],
      # Active challenges first (status != archived AND within date range)
      desc:
        fragment(
          "CASE WHEN ? != 'archived' AND ? <= ? AND ? >= ? THEN 1 ELSE 0 END",
          c.status,
          c.start_date,
          ^now,
          c.end_date,
          ^now
        ),
      # Then by start_date descending
      desc: c.start_date
    )
  end

  defp apply_ordering(query, :start_date_asc) do
    order_by(query, [c], asc: c.start_date)
  end

  defp apply_ordering(query, :start_date_desc) do
    order_by(query, [c], desc: c.start_date)
  end

  defp to_summary_dto(%Challenge{} = challenge) do
    %{
      id: challenge.id,
      name: challenge.name,
      start_date: challenge.start_date,
      end_date: challenge.end_date,
      status: String.to_atom(challenge.status),
      is_active: Challenge.active?(challenge),
      display_label: format_display_label(challenge)
    }
  end

  defp format_display_label(%Challenge{} = challenge) do
    status_badge =
      if Challenge.active?(challenge) do
        " (Active)"
      else
        ""
      end

    "#{challenge.name}#{status_badge}"
  end
end
