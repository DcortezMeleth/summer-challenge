defmodule SummerChallenge.Teams do
  @moduledoc """
  Context for team management.

  Teams are global across all challenges. Each user belongs to at most one team
  at a time. Teams have an optional owner who (along with admins) can rename or
  delete the team. When a team is deleted all members become teamless.
  """

  import Ecto.Query, warn: false

  alias SummerChallenge.Model.Team
  alias SummerChallenge.Model.User
  alias SummerChallenge.Repo

  @team_size_cap 5

  @doc "Returns the hard-coded maximum number of members per team."
  @spec team_size_cap() :: pos_integer()
  def team_size_cap, do: @team_size_cap

  @doc """
  Lists all teams ordered alphabetically, with members and owner preloaded.
  """
  @spec list_teams() :: [map()]
  def list_teams do
    Team
    |> order_by([t], asc: t.name)
    |> preload([:members, :owner])
    |> Repo.all()
    |> Enum.map(&team_to_dto/1)
  end

  @doc """
  Gets a single team by ID with members and owner preloaded.
  """
  @spec get_team(Ecto.UUID.t()) :: {:ok, map()} | {:error, :not_found}
  def get_team(team_id) do
    Team
    |> where([t], t.id == ^team_id)
    |> preload([:members, :owner])
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      team -> {:ok, team_to_dto(team)}
    end
  end

  @doc """
  Creates a new team with the given user as owner and first member.

  Returns `{:error, :already_in_team}` if the user already belongs to a team.
  """
  @spec create_team(Ecto.UUID.t(), map()) ::
          {:ok, map()}
          | {:error, :already_in_team | :user_not_found | Ecto.Changeset.t()}
  def create_team(user_id, attrs) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :user_not_found}

      %User{team_id: existing_team_id} when not is_nil(existing_team_id) ->
        {:error, :already_in_team}

      user ->
        Repo.transaction(fn ->
          attrs_with_owner = Map.put(attrs, :owner_user_id, user.id)

          case %Team{} |> Team.changeset(attrs_with_owner) |> Repo.insert() do
            {:ok, team} ->
              user
              |> Ecto.Changeset.change(%{team_id: team.id})
              |> Repo.update!()

              team = Repo.preload(team, [:members, :owner])
              team_to_dto(team)

            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end)
    end
  end

  @doc """
  Adds a user to an existing team.

  Returns `{:error, :already_in_team}` if the user already belongs to a team.
  Returns `{:error, :team_full}` if the team has reached the size cap.
  """
  @spec join_team(Ecto.UUID.t(), Ecto.UUID.t()) ::
          {:ok, map()}
          | {:error, :already_in_team | :team_full | :user_not_found | :not_found}
  def join_team(user_id, team_id) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :user_not_found}

      %User{team_id: existing_team_id} when not is_nil(existing_team_id) ->
        {:error, :already_in_team}

      user ->
        Repo.transaction(fn ->
          case Repo.get(Team, team_id) do
            nil ->
              Repo.rollback(:not_found)

            team ->
              member_count =
                User
                |> where([u], u.team_id == ^team_id)
                |> Repo.aggregate(:count)

              if member_count >= @team_size_cap do
                Repo.rollback(:team_full)
              else
                user
                |> Ecto.Changeset.change(%{team_id: team.id})
                |> Repo.update!()

                team = Repo.preload(team, [:members, :owner], force: true)
                team_to_dto(team)
              end
          end
        end)
    end
  end

  @doc """
  Removes a user from their current team.

  If the user is the team owner, ownership is cleared from the team record.
  The team itself is not deleted — an admin can manage ownerless teams.
  """
  @spec leave_team(Ecto.UUID.t()) :: {:ok, :left} | {:error, :not_in_team | :user_not_found}
  def leave_team(user_id) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :user_not_found}

      %User{team_id: nil} ->
        {:error, :not_in_team}

      user ->
        Repo.transaction(fn ->
          team = Repo.get!(Team, user.team_id)

          if team.owner_user_id == user.id do
            team
            |> Ecto.Changeset.change(%{owner_user_id: nil})
            |> Repo.update!()
          end

          user
          |> Ecto.Changeset.change(%{team_id: nil})
          |> Repo.update!()

          :left
        end)
    end
  end

  @doc """
  Renames a team. Only the team owner or an admin may rename.
  """
  @spec rename_team(Ecto.UUID.t(), Ecto.UUID.t(), String.t()) ::
          {:ok, map()}
          | {:error, :not_found | :user_not_found | :unauthorized | Ecto.Changeset.t()}
  def rename_team(team_id, requesting_user_id, new_name) do
    with {:team, %Team{} = team} <- {:team, Repo.get(Team, team_id)},
         {:user, %User{} = user} <- {:user, Repo.get(User, requesting_user_id)},
         :ok <- authorize_manage_team(team, user) do
      team
      |> Team.rename_changeset(%{name: new_name})
      |> Repo.update()
      |> case do
        {:ok, updated_team} ->
          updated_team = Repo.preload(updated_team, [:members, :owner])
          {:ok, team_to_dto(updated_team)}

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      {:team, nil} -> {:error, :not_found}
      {:user, nil} -> {:error, :user_not_found}
      {:error, :unauthorized} -> {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a team. Only the team owner or an admin may delete.

  All current members are made teamless as part of the deletion.
  """
  @spec delete_team(Ecto.UUID.t(), Ecto.UUID.t()) ::
          {:ok, :deleted} | {:error, :not_found | :user_not_found | :unauthorized}
  def delete_team(team_id, requesting_user_id) do
    with {:team, %Team{} = team} <- {:team, Repo.get(Team, team_id)},
         {:user, %User{} = user} <- {:user, Repo.get(User, requesting_user_id)},
         :ok <- authorize_manage_team(team, user) do
      Repo.transaction(fn ->
        User
        |> where([u], u.team_id == ^team_id)
        |> Repo.update_all(set: [team_id: nil])

        Repo.delete!(team)
        :deleted
      end)
    else
      {:team, nil} -> {:error, :not_found}
      {:user, nil} -> {:error, :user_not_found}
      {:error, :unauthorized} -> {:error, :unauthorized}
    end
  end

  # Private helpers

  @spec authorize_manage_team(Team.t(), User.t()) :: :ok | {:error, :unauthorized}
  defp authorize_manage_team(team, user) do
    if team.owner_user_id == user.id or user.is_admin do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  @spec team_to_dto(Team.t()) :: map()
  defp team_to_dto(%Team{} = team) do
    members =
      if Ecto.assoc_loaded?(team.members) do
        Enum.map(team.members, &member_to_dto/1)
      else
        []
      end

    %{
      id: team.id,
      name: team.name,
      owner_user_id: team.owner_user_id,
      member_count: length(members),
      members: members,
      inserted_at: team.inserted_at,
      updated_at: team.updated_at
    }
  end

  @spec member_to_dto(User.t()) :: map()
  defp member_to_dto(%User{} = user) do
    %{
      id: user.id,
      display_name: user.display_name || "Unknown",
      profile_image_url: user.profile_image_url
    }
  end
end
