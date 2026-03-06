defmodule SummerChallengeWeb.TeamsLive do
  @moduledoc """
  LiveView for team management.

  Allows authenticated users to create a team, join an existing team,
  leave their team, and (for owners/admins) rename or delete a team.
  Teams are global across all challenges.
  """

  use SummerChallengeWeb, :live

  alias SummerChallenge.Teams

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_scope.authenticated? do
      user_id = socket.assigns.current_scope.user_id

      socket =
        socket
        |> load_teams(user_id)
        |> assign(:show_create, false)
        |> assign(:show_rename, false)
        |> assign(:confirm_delete, false)
        |> assign(:confirm_leave, false)
        |> assign(:create_form, build_name_form())
        |> assign(:rename_form, nil)

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please sign in to view teams.")
       |> push_navigate(to: "/leaderboard")}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("show_create", _params, socket) do
    {:noreply, assign(socket, show_create: true, create_form: build_name_form())}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply,
     assign(socket,
       show_create: false,
       show_rename: false,
       confirm_delete: false,
       confirm_leave: false
     )}
  end

  def handle_event("validate_create", %{"team" => params}, socket) do
    form = params |> validate_name() |> Map.put(:action, :validate) |> to_form(as: "team")
    {:noreply, assign(socket, :create_form, form)}
  end

  def handle_event("create_team", %{"team" => %{"name" => name}}, socket) do
    user_id = socket.assigns.current_scope.user_id

    case Teams.create_team(user_id, %{name: name}) do
      {:ok, team} ->
        {:noreply,
         socket
         |> reload_teams(user_id)
         |> assign(:show_create, false)
         |> put_flash(:info, "Team \"#{team.name}\" created!")}

      {:error, :already_in_team} ->
        {:noreply, put_flash(socket, :error, "You are already in a team.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :create_form, to_form(changeset, as: "team"))}
    end
  end

  def handle_event("join_team", %{"team_id" => team_id}, socket) do
    user_id = socket.assigns.current_scope.user_id

    case Teams.join_team(user_id, team_id) do
      {:ok, team} ->
        {:noreply,
         socket
         |> reload_teams(user_id)
         |> put_flash(:info, "Joined team \"#{team.name}\"!")}

      {:error, :already_in_team} ->
        {:noreply, put_flash(socket, :error, "You are already in a team.")}

      {:error, :team_full} ->
        {:noreply, put_flash(socket, :error, "That team is full.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Team not found.")}
    end
  end

  def handle_event("confirm_leave", _params, socket) do
    {:noreply, assign(socket, :confirm_leave, true)}
  end

  def handle_event("leave_team", _params, socket) do
    user_id = socket.assigns.current_scope.user_id

    case Teams.leave_team(user_id) do
      {:ok, :left} ->
        {:noreply,
         socket
         |> reload_teams(user_id)
         |> assign(:confirm_leave, false)
         |> put_flash(:info, "You have left the team.")}

      {:error, :not_in_team} ->
        {:noreply, put_flash(socket, :error, "You are not in a team.")}
    end
  end

  def handle_event("show_rename", _params, socket) do
    rename_form = build_name_form(%{}, socket.assigns.current_team.name)
    {:noreply, assign(socket, show_rename: true, rename_form: rename_form)}
  end

  def handle_event("validate_rename", %{"team" => params}, socket) do
    form = params |> validate_name() |> Map.put(:action, :validate) |> to_form(as: "team")
    {:noreply, assign(socket, :rename_form, form)}
  end

  def handle_event("rename_team", %{"team" => %{"name" => name}}, socket) do
    team_id = socket.assigns.current_team.id
    user_id = socket.assigns.current_scope.user_id

    case Teams.rename_team(team_id, user_id, name) do
      {:ok, updated_team} ->
        {:noreply,
         socket
         |> reload_teams(user_id)
         |> assign(:show_rename, false)
         |> put_flash(:info, "Team renamed to \"#{updated_team.name}\".")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to rename this team.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :rename_form, to_form(changeset, as: "team"))}
    end
  end

  def handle_event("confirm_delete", _params, socket) do
    {:noreply, assign(socket, :confirm_delete, true)}
  end

  def handle_event("delete_team", _params, socket) do
    team_id = socket.assigns.current_team.id
    user_id = socket.assigns.current_scope.user_id

    case Teams.delete_team(team_id, user_id) do
      {:ok, :deleted} ->
        {:noreply,
         socket
         |> reload_teams(user_id)
         |> assign(:confirm_delete, false)
         |> put_flash(:info, "Team deleted.")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to delete this team.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main id="main-content" class="min-h-screen bg-gradient-to-b from-brand-50 via-ui-50 to-ui-50" role="main">
      <div class="mx-auto max-w-5xl px-4 py-10">
        <header class="mb-8">
          <p class="text-xs font-semibold tracking-widest text-orange-500 uppercase">
            Summer Challenge
          </p>
          <h1 class="mt-2 text-3xl font-bold tracking-tight text-ui-900">Teams</h1>
          <p class="mt-2 text-sm text-ui-700 max-w-prose">
            Compete together. Teams are global across all challenges and appear on leaderboards.
          </p>
        </header>

        <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
          <!-- Left column: My Team -->
          <div class="lg:col-span-2 space-y-4">
            <.my_team_section {assigns} />
          </div>

          <!-- Right column: All Teams -->
          <div class="space-y-4">
            <.all_teams_section {assigns} />
          </div>
        </div>
      </div>
    </main>
    """
  end

  # ---------------------------------------------------------------------------
  # Components
  # ---------------------------------------------------------------------------

  defp my_team_section(%{current_team: nil} = assigns) do
    ~H"""
    <section aria-label="My Team">
      <h2 class="text-lg font-semibold text-ui-900 mb-3">My Team</h2>

      <div class="bg-white rounded-2xl shadow-sport ring-1 ring-ui-200 p-6">
        <div class="flex flex-col items-center text-center py-4 gap-4">
          <div class="h-14 w-14 rounded-full bg-ui-100 flex items-center justify-center">
            <.icon name="hero-user-group" class="h-7 w-7 text-ui-400" />
          </div>
          <div>
            <p class="font-semibold text-ui-900">You're not on a team yet</p>
            <p class="mt-1 text-sm text-ui-600">
              Create your own team or join one from the list.
            </p>
          </div>

          <button
            :if={!@show_create}
            phx-click="show_create"
            class="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-brand-700 transition-colors"
          >
            <.icon name="hero-plus" class="h-4 w-4" />
            Create a Team
          </button>
        </div>

        <div :if={@show_create} class="border-t border-ui-100 mt-4 pt-4">
          <h3 class="text-sm font-semibold text-ui-900 mb-3">New Team</h3>
          <.form
            for={@create_form}
            phx-submit="create_team"
            phx-change="validate_create"
            class="space-y-4"
          >
            <.input
              field={@create_form[:name]}
              label="Team name"
              placeholder="e.g. Flying Foxes"
              phx-debounce="300"
            />
            <div class="flex gap-2">
              <button
                type="submit"
                class="rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-brand-700 transition-colors"
              >
                Create Team
              </button>
              <button
                type="button"
                phx-click="cancel"
                class="rounded-lg bg-ui-100 px-4 py-2 text-sm font-semibold text-ui-700 hover:bg-ui-200 transition-colors"
              >
                Cancel
              </button>
            </div>
          </.form>
        </div>
      </div>
    </section>
    """
  end

  defp my_team_section(assigns) do
    ~H"""
    <section aria-label="My Team">
      <h2 class="text-lg font-semibold text-ui-900 mb-3">My Team</h2>

      <div class="bg-white rounded-2xl shadow-sport ring-1 ring-ui-200 overflow-hidden">
        <!-- Team header -->
        <div class="bg-gradient-to-r from-brand-900 to-brand-700 px-6 py-4 flex items-center justify-between">
          <div>
            <p class="text-xs font-semibold tracking-widest text-brand-300 uppercase">Team</p>
            <h3 class="mt-0.5 text-xl font-bold text-white"><%= @current_team.name %></h3>
          </div>
          <span class="text-sm text-brand-300">
            <%= @current_team.member_count %>/<%= @team_size_cap %> members
          </span>
        </div>

        <!-- Members list -->
        <ul class="divide-y divide-ui-100" role="list" aria-label="Team members">
          <li :for={member <- @current_team.members} class="flex items-center gap-3 px-6 py-3">
            <%= if member.profile_image_url do %>
              <img
                src={member.profile_image_url}
                alt={member.display_name}
                class="h-8 w-8 rounded-full object-cover shadow-sm ring-2 ring-brand-400/50 flex-shrink-0"
              />
            <% else %>
              <div class="h-8 w-8 rounded-full bg-gradient-to-br from-brand-400 to-brand-600 flex items-center justify-center text-white font-bold text-sm shadow-sm ring-2 ring-brand-400/50 flex-shrink-0">
                <%= String.first(member.display_name) %>
              </div>
            <% end %>
            <span class="text-sm font-medium text-ui-900"><%= member.display_name %></span>
            <span
              :if={member.id == @current_team.owner_user_id}
              class="ml-auto text-xs font-medium text-brand-600 bg-brand-50 ring-1 ring-brand-200 rounded-full px-2 py-0.5"
            >
              Owner
            </span>
          </li>
        </ul>

        <!-- Rename form (inline) -->
        <div :if={@show_rename} class="border-t border-ui-100 px-6 py-4">
          <h4 class="text-sm font-semibold text-ui-900 mb-3">Rename Team</h4>
          <.form
            for={@rename_form}
            phx-submit="rename_team"
            phx-change="validate_rename"
            class="space-y-4"
          >
            <.input
              field={@rename_form[:name]}
              label="New name"
              phx-debounce="300"
            />
            <div class="flex gap-2">
              <button
                type="submit"
                class="rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-brand-700 transition-colors"
              >
                Save
              </button>
              <button
                type="button"
                phx-click="cancel"
                class="rounded-lg bg-ui-100 px-4 py-2 text-sm font-semibold text-ui-700 hover:bg-ui-200 transition-colors"
              >
                Cancel
              </button>
            </div>
          </.form>
        </div>

        <!-- Delete confirmation -->
        <div :if={@confirm_delete} class="border-t border-rose-100 bg-rose-50 px-6 py-4">
          <div class="flex items-start gap-3">
            <.icon name="hero-exclamation-triangle" class="h-5 w-5 text-rose-600 flex-shrink-0 mt-0.5" />
            <div class="flex-1">
              <p class="text-sm font-semibold text-rose-800">Delete this team?</p>
              <p class="mt-1 text-xs text-rose-700">
                All members will become teamless. This cannot be undone.
              </p>
              <div class="mt-3 flex gap-2">
                <button
                  phx-click="delete_team"
                  class="rounded-lg bg-rose-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-rose-700 transition-colors"
                >
                  Yes, delete
                </button>
                <button
                  phx-click="cancel"
                  class="rounded-lg bg-white px-3 py-1.5 text-xs font-semibold text-ui-700 ring-1 ring-ui-300 hover:bg-ui-50 transition-colors"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Leave confirmation -->
        <div :if={@confirm_leave} class="border-t border-amber-100 bg-amber-50 px-6 py-4">
          <div class="flex items-start gap-3">
            <.icon name="hero-exclamation-triangle" class="h-5 w-5 text-amber-600 flex-shrink-0 mt-0.5" />
            <div class="flex-1">
              <p class="text-sm font-semibold text-amber-800">Leave this team?</p>
              <p class="mt-1 text-xs text-amber-700">
                You can rejoin or join another team at any time.
              </p>
              <div class="mt-3 flex gap-2">
                <button
                  phx-click="leave_team"
                  class="rounded-lg bg-amber-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-amber-700 transition-colors"
                >
                  Yes, leave
                </button>
                <button
                  phx-click="cancel"
                  class="rounded-lg bg-white px-3 py-1.5 text-xs font-semibold text-ui-700 ring-1 ring-ui-300 hover:bg-ui-50 transition-colors"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Action buttons -->
        <div
          :if={!@show_rename and !@confirm_delete and !@confirm_leave}
          class="border-t border-ui-100 px-6 py-3 flex flex-wrap gap-2"
        >
          <button
            :if={can_manage_team?(@current_team, @current_scope)}
            phx-click="show_rename"
            class="inline-flex items-center gap-1.5 rounded-lg bg-ui-100 px-3 py-1.5 text-xs font-semibold text-ui-700 hover:bg-ui-200 transition-colors"
          >
            <.icon name="hero-pencil" class="h-3.5 w-3.5" />
            Rename
          </button>
          <button
            :if={can_manage_team?(@current_team, @current_scope)}
            phx-click="confirm_delete"
            class="inline-flex items-center gap-1.5 rounded-lg bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 ring-1 ring-rose-200 hover:bg-rose-100 transition-colors"
          >
            <.icon name="hero-trash" class="h-3.5 w-3.5" />
            Delete Team
          </button>
          <button
            phx-click="confirm_leave"
            class="inline-flex items-center gap-1.5 rounded-lg bg-ui-100 px-3 py-1.5 text-xs font-semibold text-ui-700 hover:bg-ui-200 transition-colors ml-auto"
          >
            <.icon name="hero-arrow-right-on-rectangle" class="h-3.5 w-3.5" />
            Leave Team
          </button>
        </div>
      </div>
    </section>
    """
  end

  defp all_teams_section(assigns) do
    ~H"""
    <section aria-label="All Teams">
      <h2 class="text-lg font-semibold text-ui-900 mb-3">All Teams</h2>

      <div :if={@teams == []} class="bg-white rounded-2xl shadow-sport ring-1 ring-ui-200 p-6 text-center">
        <.icon name="hero-user-group" class="mx-auto h-8 w-8 text-ui-400" />
        <p class="mt-2 text-sm text-ui-600">No teams yet. Be the first to create one!</p>
      </div>

      <ul :if={@teams != []} class="space-y-3" role="list">
        <li :for={team <- @teams} class="bg-white rounded-xl shadow-sport ring-1 ring-ui-200 overflow-hidden">
          <div class="px-4 py-3 flex items-start justify-between gap-3">
            <div class="min-w-0 flex-1">
              <p class="font-semibold text-ui-900 truncate"><%= team.name %></p>
              <p class="mt-0.5 text-xs text-ui-500">
                <%= team.member_count %>/<%= @team_size_cap %> members
              </p>
              <ul :if={team.members != []} class="mt-1.5 flex flex-wrap gap-1">
                <li
                  :for={member <- team.members}
                  class="text-xs text-ui-600 bg-ui-50 ring-1 ring-ui-200 rounded-full px-2 py-0.5 truncate max-w-[8rem]"
                >
                  <%= member.display_name %>
                </li>
              </ul>
            </div>

            <div class="flex-shrink-0">
              <span
                :if={my_team?(team, @current_team)}
                class="text-xs font-semibold text-brand-700 bg-brand-50 ring-1 ring-brand-200 rounded-full px-2.5 py-1"
              >
                My team
              </span>

              <button
                :if={is_nil(@current_team) and team.member_count < @team_size_cap}
                phx-click="join_team"
                phx-value-team_id={team.id}
                class="rounded-lg bg-brand-600 px-3 py-1.5 text-xs font-semibold text-white shadow-sm hover:bg-brand-700 transition-colors"
              >
                Join
              </button>

              <span
                :if={is_nil(@current_team) and team.member_count >= @team_size_cap}
                class="text-xs text-ui-500 bg-ui-100 rounded-full px-2.5 py-1"
              >
                Full
              </span>
            </div>
          </div>
        </li>
      </ul>
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp load_teams(socket, user_id) do
    all_teams = Teams.list_teams()

    current_team =
      Enum.find(all_teams, fn t ->
        Enum.any?(t.members, &(&1.id == user_id))
      end)

    socket
    |> assign(:current_team, current_team)
    |> assign(:teams, all_teams)
    |> assign(:team_size_cap, Teams.team_size_cap())
  end

  defp reload_teams(socket, user_id) do
    all_teams = Teams.list_teams()

    current_team =
      Enum.find(all_teams, fn t ->
        Enum.any?(t.members, &(&1.id == user_id))
      end)

    socket
    |> assign(:current_team, current_team)
    |> assign(:teams, all_teams)
  end

  defp build_name_form(attrs \\ %{}, initial_name \\ nil) do
    data = %{name: initial_name || ""}
    types = %{name: :string}

    {data, types}
    |> Ecto.Changeset.cast(attrs, [:name])
    |> to_form(as: "team")
  end

  defp validate_name(params) do
    data = %{name: ""}
    types = %{name: :string}

    {data, types}
    |> Ecto.Changeset.cast(params, [:name])
    |> Ecto.Changeset.validate_required([:name], message: "Team name cannot be blank")
    |> Ecto.Changeset.validate_length(:name, min: 1, max: 80)
    |> Ecto.Changeset.validate_change(:name, fn :name, value ->
      if String.trim(value) == "", do: [name: "Team name cannot be blank"], else: []
    end)
  end

  defp can_manage_team?(team, current_scope) do
    current_scope.user_id == team.owner_user_id or current_scope.is_admin
  end

  defp my_team?(_team, nil), do: false

  defp my_team?(team, current_team), do: team.id == current_team.id
end
