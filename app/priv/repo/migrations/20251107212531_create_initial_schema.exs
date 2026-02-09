defmodule SummerChallenge.Repo.Migrations.CreateInitialSchema do
  use Ecto.Migration

  @moduledoc """
  Initial database schema migration for Summer Challenge application.

  This migration creates the core database structure including:
  - Users table for athlete profiles and Strava integration
  - Teams table for team-based competitions
  - Activities table for storing Strava activity data
  - User credentials table for encrypted Strava API tokens
  - Sync runs table for tracking data synchronization operations

  Key design decisions:
  - UUID primary keys using PostgreSQL's gen_random_uuid()
  - UTC timestamps (timestamptz) for all temporal data
  - Encrypted storage for sensitive credential data
  - Generated columns for simplified querying (sport_category)
  - Comprehensive constraints and indexes for data integrity and performance

  Security considerations:
  - Row-Level Security (RLS) is NOT enabled in MVP - authorization handled in application layer
  - Encrypted credentials using Cloak Ecto at application level
  - Foreign key constraints prevent orphaned records
  """

  def up do
    # Enable pgcrypto extension for UUID generation
    execute("create extension if not exists pgcrypto")

    # Create teams table first (referenced by users)
    create table(:teams, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :text, null: false
      add :owner_user_id, :uuid
      timestamps(type: :timestamptz)
    end

    # Create users table
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :display_name, :text, null: false
      add :strava_athlete_id, :bigint
      add :joined_at, :timestamptz
      add :counting_started_at, :timestamptz
      add :last_synced_at, :timestamptz
      add :last_sync_error, :text
      add :is_admin, :boolean, null: false, default: false
      add :team_id, :uuid
      timestamps(type: :timestamptz)
    end

    # Create activities table
    create table(:activities, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, :uuid, null: false
      add :strava_id, :bigint, null: false
      add :sport_type, :text, null: false
      add :start_at, :timestamptz, null: false
      add :distance_m, :integer, null: false
      add :moving_time_s, :integer, null: false
      add :elev_gain_m, :integer, null: false
      add :excluded, :boolean, null: false, default: false
      timestamps(type: :timestamptz)
    end

    # Add generated column for sport category (run vs ride)
    # This simplifies leaderboard filtering without complex queries
    execute("""
    alter table activities
    add column sport_category text generated always as (
      case
        when sport_type in ('Run','TrailRun') then 'run'
        when sport_type in ('Ride','GravelRide','MountainBikeRide') then 'ride'
        else null
      end
    ) stored
    """)

    # Create user credentials table (one-to-one with users)
    create table(:user_credentials, primary_key: false) do
      add :user_id, :uuid, primary_key: true
      add :access_token_enc, :bytea, null: false
      add :refresh_token_enc, :bytea, null: false
      add :expires_at, :timestamptz, null: false
      timestamps(type: :timestamptz)
    end

    # Create sync runs table (standalone tracking table)
    create table(:sync_runs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :started_at, :timestamptz, null: false, default: fragment("now()")
      add :finished_at, :timestamptz
      add :status, :text, null: false
      add :stats, :jsonb, null: false, default: "{}"
      timestamps(type: :timestamptz)
    end

    # Add constraints after table creation
    # Note: CHECK constraints are added separately for clarity

    # Teams constraints
    create constraint(:teams, :teams_name_length_check,
             check: "char_length(name) between 1 and 80"
           )

    # Users constraints
    create constraint(:users, :users_display_name_length_check,
             check: "char_length(display_name) between 1 and 80"
           )

    create constraint(:users, :users_distance_positive_check,
             check: "distance_m >= 0",
             table: :activities
           )

    create constraint(:users, :users_moving_time_positive_check,
             check: "moving_time_s >= 0",
             table: :activities
           )

    create constraint(:users, :users_elev_gain_positive_check,
             check: "elev_gain_m >= 0",
             table: :activities
           )

    # Activities constraints
    create constraint(:activities, :activities_sport_type_check,
             check: "sport_type in ('Run','TrailRun','Ride','GravelRide','MountainBikeRide')"
           )

    # Sync runs constraints
    create constraint(:sync_runs, :sync_runs_status_check,
             check: "status in ('running','success','error','cancelled')"
           )

    # Add foreign key constraints
    # Note: Ecto automatically creates FK constraints when using references(),
    # but we're being explicit here for clarity

    alter table(:users) do
      modify :team_id, references(:teams, type: :uuid, on_delete: :nothing)
    end

    alter table(:teams) do
      modify :owner_user_id, references(:users, type: :uuid, on_delete: :nothing)
    end

    alter table(:activities) do
      modify :user_id, references(:users, type: :uuid, on_delete: :restrict)
    end

    alter table(:user_credentials) do
      modify :user_id, references(:users, type: :uuid, on_delete: :delete_all)
    end

    # Create unique indexes
    create unique_index(:users, [:display_name])
    create unique_index(:users, [:strava_athlete_id])
    create unique_index(:teams, [:name])
    create unique_index(:activities, [:strava_id])

    # Create performance indexes
    create index(:users, [:team_id])
    create index(:teams, [:owner_user_id])
    create index(:activities, [:user_id, :start_at])
    create index(:activities, [:user_id, :sport_category, :start_at], where: "excluded = false")
    create index(:sync_runs, [:started_at])

    # Note: Row-Level Security (RLS) policies are intentionally NOT created
    # in this MVP. Authorization will be handled in the application layer
    # as specified in the requirements.
  end

  def down do
    # WARNING: This migration is destructive and will remove all data
    # In a production environment, consider backing up data before rollback

    drop table(:sync_runs)
    drop table(:user_credentials)
    drop table(:activities)
    drop table(:users)
    drop table(:teams)

    # Note: We don't drop the pgcrypto extension as it might be used by other databases
    # execute("drop extension if exists pgcrypto")
  end
end
