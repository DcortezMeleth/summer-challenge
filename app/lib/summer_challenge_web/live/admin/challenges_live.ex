defmodule SummerChallengeWeb.Admin.ChallengesLive do
  @moduledoc """
  LiveView for admin challenge management.

  Allows admins to:
  - List all challenges (including archived)
  - Create new challenges
  - Edit existing challenges
  - Delete future challenges
  - Archive past challenges
  - Clone challenges
  """
  use SummerChallengeWeb, :live

  require Logger
  alias SummerChallenge.Challenges
  alias SummerChallenge.Model.Challenge
  alias SummerChallenge.Workers.SyncAllWorker

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Admin Dashboard")
     |> assign(:show_form, false)
     |> assign(:form_mode, nil)
     |> assign(:selected_challenge, nil)
     |> assign(:syncing, false)
     |> load_challenges()
     |> load_stats()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Admin Dashboard")
    |> assign(:show_form, false)
    |> assign(:form_mode, nil)
    |> assign(:selected_challenge, nil)
  end

  defp apply_action(socket, :new, _params) do
    changeset = Challenge.changeset(%Challenge{}, %{})

    socket
    |> assign(:page_title, "New Challenge")
    |> assign(:show_form, true)
    |> assign(:form_mode, :new)
    |> assign(:selected_challenge, nil)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    case Challenges.get_challenge(id) do
      {:ok, challenge} ->
        changeset = Challenge.changeset(challenge, %{})

        socket
        |> assign(:page_title, "Edit Challenge")
        |> assign(:show_form, true)
        |> assign(:form_mode, :edit)
        |> assign(:selected_challenge, challenge)
        |> assign(:form, to_form(changeset))

      {:error, :not_found} ->
        socket
        |> put_flash(:error, "Challenge not found")
        |> push_navigate(to: ~p"/admin")
    end
  end

  defp apply_action(socket, :clone, %{"id" => id}) do
    case Challenges.get_challenge(id) do
      {:ok, challenge} ->
        # Prepare clone with default values
        clone_attrs = %{
          name: "Copy of #{challenge.name}",
          start_date: nil,
          end_date: nil,
          allowed_sport_types: challenge.allowed_sport_types,
          status: "inactive"
        }

        changeset = Challenge.changeset(%Challenge{}, clone_attrs)

        socket
        |> assign(:page_title, "Clone Challenge")
        |> assign(:show_form, true)
        |> assign(:form_mode, :clone)
        |> assign(:selected_challenge, challenge)
        |> assign(:form, to_form(changeset))

      {:error, :not_found} ->
        socket
        |> put_flash(:error, "Challenge not found")
        |> push_navigate(to: ~p"/admin")
    end
  end

  @impl true
  def handle_event("validate", %{"challenge" => challenge_params}, socket) do
    changeset =
      case socket.assigns.form_mode do
        :edit ->
          socket.assigns.selected_challenge
          |> Challenge.changeset(challenge_params)
          |> Map.put(:action, :validate)

        _ ->
          %Challenge{}
          |> Challenge.changeset(challenge_params)
          |> Map.put(:action, :validate)
      end

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("force_sync", _params, socket) do
    if socket.assigns.current_scope.is_admin do
      Logger.info("Admin #{socket.assigns.current_scope.user_id} triggered manual sync")

      case SyncAllWorker.new(%{}) |> Oban.insert() do
        {:ok, _job} ->
          {:noreply,
           socket
           |> assign(:syncing, true)
           |> put_flash(:info, "Sync job queued successfully! It will start processing shortly.")
           |> load_stats()}

        {:error, reason} ->
          Logger.error("Failed to queue sync job: #{inspect(reason)}")

          {:noreply,
           put_flash(
             socket,
             :error,
             "Failed to queue sync job. Please try again or check logs."
           )}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  def handle_event("save", %{"challenge" => challenge_params}, socket) do
    case socket.assigns.form_mode do
      :new ->
        create_challenge(socket, challenge_params)

      :edit ->
        update_challenge(socket, socket.assigns.selected_challenge, challenge_params)

      :clone ->
        create_challenge(socket, challenge_params)
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Challenges.get_challenge(id) do
      {:ok, challenge} ->
        case Challenges.delete_challenge(challenge) do
          {:ok, _challenge} ->
            {:noreply,
             socket
             |> put_flash(:info, "Challenge deleted successfully")
             |> load_challenges()}

          {:error, :cannot_delete} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Cannot delete a challenge that has already started"
             )}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to delete challenge")}
        end

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Challenge not found")}
    end
  end

  @impl true
  def handle_event("archive", %{"id" => id}, socket) do
    case Challenges.get_challenge(id) do
      {:ok, challenge} ->
        case Challenges.archive_challenge(challenge) do
          {:ok, _challenge} ->
            {:noreply,
             socket
             |> put_flash(:info, "Challenge archived successfully")
             |> load_challenges()}

          {:error, :cannot_archive} ->
            {:noreply,
             put_flash(socket, :error, "Cannot archive a challenge that hasn't ended yet")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to archive challenge")}
        end

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Challenge not found")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-brand-50 via-ui-50 to-ui-50">
      <div class="mx-auto max-w-7xl px-4 py-10">
        <div class="mb-8">
          <.link navigate={~p"/leaderboard"} class="text-sm text-brand-600 hover:text-brand-700 font-medium">
            ← Back to Leaderboards
          </.link>
        </div>

        <header class="mb-8">
          <h1 class="text-3xl font-bold tracking-tight text-ui-900">
            Admin Dashboard
          </h1>
          <p class="mt-2 text-sm text-ui-700">
            System management, activity sync, and challenge administration
          </p>
        </header>

        <!-- System Stats & Sync Control -->
        <div class="mb-8 space-y-6">
          <!-- Stats Cards -->
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <.stat_card
              title="Total Users"
              value={@stats.total_users}
              icon="hero-users"
              color="blue"
            />
            <.stat_card
              title="Users with Credentials"
              value={@stats.syncable_users}
              icon="hero-user-circle"
              color="green"
            />
            <.stat_card
              title="Pending Jobs"
              value={@stats.pending_jobs}
              icon="hero-clock"
              color="yellow"
            />
            <.stat_card
              title="Failed Jobs (24h)"
              value={@stats.failed_jobs_24h}
              icon="hero-exclamation-triangle"
              color="red"
            />
          </div>

          <!-- Sync Control -->
          <div class="bg-white shadow-sport rounded-xl overflow-hidden ring-1 ring-ui-200">
            <div class="px-6 py-4">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="text-sm font-semibold text-ui-900">Activity Sync</h3>
                  <p class="mt-1 text-xs text-ui-600">
                    <span class="font-medium">Next scheduled:</span> Midnight (Europe/Warsaw)
                    <span class="mx-2">•</span>
                    <span class="font-medium">Last sync:</span> <%= @stats.last_sync_at || "Never" %>
                  </p>
                </div>

                <button
                  phx-click="force_sync"
                  disabled={@syncing}
                  class={[
                    "inline-flex items-center gap-2 px-4 py-2 rounded-lg font-medium text-sm",
                    "transition-colors duration-150",
                    if(@syncing,
                      do: "bg-ui-100 text-ui-400 cursor-not-allowed",
                      else: "bg-brand-600 text-white hover:bg-brand-700 active:bg-brand-800"
                    )
                  ]}
                >
                  <.icon
                    name="hero-arrow-path"
                    class={if @syncing, do: "w-5 h-5 animate-spin", else: "w-5 h-5"}
                  />
                  <%= if @syncing, do: "Syncing...", else: "Force Sync Now" %>
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Challenge Management Section -->
        <div class="border-t border-ui-200 pt-8">
          <div class="mb-6">
            <h2 class="text-xl font-semibold text-ui-900">Manage Challenges</h2>
            <p class="mt-1 text-sm text-ui-700">
              Create, edit, and manage sports challenges
            </p>
          </div>

        <%= if @show_form do %>
          <.challenge_form
            form={@form}
            mode={@form_mode}
            on_cancel={~p"/admin"}
          />
        <% else %>
          <div class="mb-6">
            <.link
              patch={~p"/admin/challenges/new"}
              class="inline-flex items-center gap-2 rounded-lg bg-brand-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-brand-600 focus:outline-none focus:ring-2 focus:ring-brand-600 focus:ring-offset-2 transition-colors"
            >
              <.icon name="hero-plus" class="w-5 h-5" />
              New Challenge
            </.link>
          </div>

          <.challenges_table challenges={@challenges} />
        <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Private functions

  defp create_challenge(socket, challenge_params) do
    case Challenges.create_challenge(challenge_params) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge created successfully")
         |> push_navigate(to: ~p"/admin")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp update_challenge(socket, challenge, challenge_params) do
    case Challenges.update_challenge(challenge, challenge_params) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge updated successfully")
         |> push_navigate(to: ~p"/admin")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp load_challenges(socket) do
    challenges = Challenges.list_challenges(include_archived: true, order_by: :start_date_desc)
    assign(socket, :challenges, challenges)
  end

  defp load_stats(socket) do
    stats = %{
      total_users: count_total_users(),
      syncable_users: count_syncable_users(),
      pending_jobs: count_pending_jobs(),
      failed_jobs_24h: count_failed_jobs_24h(),
      last_sync_at: get_last_sync_time()
    }

    assign(socket, :stats, stats)
  end

  defp count_total_users do
    SummerChallenge.Repo.aggregate(SummerChallenge.Model.User, :count)
  end

  defp count_syncable_users do
    length(SummerChallenge.Accounts.list_syncable_users())
  end

  defp count_pending_jobs do
    import Ecto.Query

    SummerChallenge.Repo.one(
      from j in Oban.Job,
        where: j.state in ["available", "scheduled", "executing"],
        select: count(j.id)
    ) || 0
  end

  defp count_failed_jobs_24h do
    import Ecto.Query

    twenty_four_hours_ago = DateTime.utc_now() |> DateTime.add(-24 * 60 * 60)

    SummerChallenge.Repo.one(
      from j in Oban.Job,
        where:
          j.state in ["retryable", "discarded"] and
            j.attempted_at >= ^twenty_four_hours_ago,
        select: count(j.id)
    ) || 0
  end

  defp get_last_sync_time do
    import Ecto.Query

    case SummerChallenge.Repo.one(
           from j in Oban.Job,
             where:
               j.worker == "SummerChallenge.Workers.SyncAllWorker" and j.state == "completed",
             order_by: [desc: j.completed_at],
             limit: 1,
             select: j.completed_at
         ) do
      nil -> nil
      datetime -> SummerChallengeWeb.Formatters.format_warsaw_datetime(datetime)
    end
  end

  # Component functions

  attr :challenges, :list, required: true

  defp challenges_table(assigns) do
    ~H"""
    <div class="bg-white shadow-sport rounded-2xl overflow-hidden ring-1 ring-ui-200">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-ui-200">
          <thead class="bg-ui-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                Challenge Name
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                Dates
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                Status
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-semibold text-ui-600 uppercase tracking-wider">
                Sport Types
              </th>
              <th scope="col" class="px-6 py-3 text-right text-xs font-semibold text-ui-600 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-ui-100">
            <%= for challenge <- @challenges do %>
              <tr class="hover:bg-ui-50 transition-colors">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-semibold text-ui-900"><%= challenge.name %></span>
                    <.status_badge challenge={challenge} />
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-ui-700">
                  <%= format_date_range(challenge) %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <.status_indicator status={challenge.status} />
                </td>
                <td class="px-6 py-4 text-sm text-ui-700">
                  <div class="flex flex-wrap gap-1">
                    <%= for sport_type <- Enum.take(challenge.allowed_sport_types, 3) do %>
                      <span class="inline-flex items-center rounded-md bg-ui-100 px-2 py-1 text-xs font-medium text-ui-700">
                        <%= sport_type %>
                      </span>
                    <% end %>
                    <%= if length(challenge.allowed_sport_types) > 3 do %>
                      <span class="inline-flex items-center rounded-md bg-ui-100 px-2 py-1 text-xs font-medium text-ui-700">
                        +<%= length(challenge.allowed_sport_types) - 3 %> more
                      </span>
                    <% end %>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <div class="flex items-center justify-end gap-2">
                    <.link
                      patch={~p"/admin/challenges/#{challenge.id}/edit"}
                      class="text-brand-600 hover:text-brand-700"
                      title="Edit"
                    >
                      <.icon name="hero-pencil" class="w-5 h-5" />
                    </.link>
                    <.link
                      patch={~p"/admin/challenges/#{challenge.id}/clone"}
                      class="text-ui-600 hover:text-ui-700"
                      title="Clone"
                    >
                      <.icon name="hero-document-duplicate" class="w-5 h-5" />
                    </.link>
                    <%= if Challenge.can_archive?(challenge) do %>
                      <button
                        phx-click="archive"
                        phx-value-id={challenge.id}
                        data-confirm="Are you sure you want to archive this challenge? It will be hidden from non-admin users."
                        class="text-amber-600 hover:text-amber-700"
                        title="Archive"
                      >
                        <.icon name="hero-archive-box" class="w-5 h-5" />
                      </button>
                    <% end %>
                    <%= if Challenge.can_delete?(challenge) do %>
                      <button
                        phx-click="delete"
                        phx-value-id={challenge.id}
                        data-confirm="Are you sure you want to delete this challenge? This action cannot be undone."
                        class="text-rose-600 hover:text-rose-700"
                        title="Delete"
                      >
                        <.icon name="hero-trash" class="w-5 h-5" />
                      </button>
                    <% end %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <%= if @challenges == [] do %>
        <div class="text-center py-12 px-6">
          <p class="text-ui-600 text-sm">No challenges found. Create your first challenge to get started.</p>
        </div>
      <% end %>
    </div>
    """
  end

  attr :form, :map, required: true
  attr :mode, :atom, required: true
  attr :on_cancel, :string, required: true

  defp challenge_form(assigns) do
    ~H"""
    <div class="bg-white shadow-sport rounded-2xl ring-1 ring-ui-200 p-6 mb-8">
      <.form for={@form} id="challenge-form" phx-change="validate" phx-submit="save">
        <div class="space-y-6">
          <div>
            <label for="challenge_name" class="block text-sm font-semibold text-ui-900 mb-2">
              Challenge Name <span class="text-rose-600">*</span>
            </label>
            <.input
              field={@form[:name]}
              type="text"
              placeholder="e.g., Summer Challenge 2026"
              required
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label for="challenge_start_date" class="block text-sm font-semibold text-ui-900 mb-2">
                Start Date <span class="text-rose-600">*</span>
              </label>
              <.input
                field={@form[:start_date]}
                type="datetime-local"
                required
              />
            </div>

            <div>
              <label for="challenge_end_date" class="block text-sm font-semibold text-ui-900 mb-2">
                End Date <span class="text-rose-600">*</span>
              </label>
              <.input
                field={@form[:end_date]}
                type="datetime-local"
                required
              />
              <p class="mt-1 text-xs text-ui-600">Minimum 7 days duration required</p>
            </div>
          </div>

          <div>
            <label class="block text-sm font-semibold text-ui-900 mb-2">
              Status
            </label>
            <.input
              field={@form[:status]}
              type="select"
              options={[{"Active", "active"}, {"Inactive", "inactive"}]}
            />
          </div>

          <div>
            <label class="block text-sm font-semibold text-ui-900 mb-3">
              Allowed Sport Types <span class="text-rose-600">*</span>
            </label>
            <.sport_type_checkboxes form={@form} />
          </div>

          <div class="flex items-center gap-3 pt-4 border-t border-ui-200">
            <button
              type="submit"
              class="inline-flex items-center gap-2 rounded-lg bg-brand-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-brand-600 focus:outline-none focus:ring-2 focus:ring-brand-600 focus:ring-offset-2 transition-colors"
            >
              <%= if @mode == :edit, do: "Update Challenge", else: "Create Challenge" %>
            </button>
            <.link
              navigate={@on_cancel}
              class="inline-flex items-center gap-2 rounded-lg bg-white px-4 py-2.5 text-sm font-semibold text-ui-700 shadow-sm ring-1 ring-inset ring-ui-300 hover:bg-ui-50 focus:outline-none focus:ring-2 focus:ring-brand-600 focus:ring-offset-2 transition-colors"
            >
              Cancel
            </.link>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  attr :form, :map, required: true

  defp sport_type_checkboxes(assigns) do
    sport_groups = Challenge.sport_type_groups()

    assigns =
      assign(assigns, :sport_groups, [
        {:running_outdoor, "Running (Outdoor)", sport_groups.running_outdoor},
        {:cycling_outdoor, "Cycling (Outdoor)", sport_groups.cycling_outdoor},
        {:running_virtual, "Running (Virtual)", sport_groups.running_virtual},
        {:cycling_virtual, "Cycling (Virtual)", sport_groups.cycling_virtual}
      ])

    ~H"""
    <div class="space-y-4">
      <%= for {_key, group_label, sport_types} <- @sport_groups do %>
        <div class="border border-ui-200 rounded-lg p-4">
          <div class="font-medium text-sm text-ui-900 mb-2"><%= group_label %></div>
          <div class="space-y-2">
            <%= for sport_type <- sport_types do %>
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  name="challenge[allowed_sport_types][]"
                  value={sport_type}
                  checked={sport_type in (@form[:allowed_sport_types].value || [])}
                  class="rounded border-ui-300 text-brand-600 focus:ring-brand-600"
                />
                <span class="text-sm text-ui-700"><%= sport_type %></span>
              </label>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :challenge, :map, required: true

  defp status_badge(assigns) do
    ~H"""
    <%= if Challenge.active?(@challenge) do %>
      <span class="inline-flex items-center rounded-full bg-brand-100 px-2 py-0.5 text-xs font-medium text-brand-800 ring-1 ring-inset ring-brand-600/20">
        Active
      </span>
    <% end %>
    """
  end

  attr :status, :string, required: true

  defp status_indicator(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset",
      case @status do
        "active" -> "bg-brand-50 text-brand-700 ring-brand-600/20"
        "inactive" -> "bg-ui-50 text-ui-700 ring-ui-600/20"
        "archived" -> "bg-amber-50 text-amber-700 ring-amber-600/20"
      end
    ]}>
      <%= String.capitalize(@status) %>
    </span>
    """
  end

  defp format_date_range(challenge) do
    start_str = Calendar.strftime(challenge.start_date, "%b %d, %Y")
    end_str = Calendar.strftime(challenge.end_date, "%b %d, %Y")
    "#{start_str} - #{end_str}"
  end

  defp stat_card(assigns) do
    ~H"""
    <div class="bg-white shadow-sport rounded-xl overflow-hidden ring-1 ring-ui-200">
      <div class="px-6 py-5">
        <div class="flex items-center">
          <div class={[
            "flex-shrink-0 rounded-lg p-3",
            stat_color_class(@color)
          ]}>
            <.icon name={@icon} class="w-6 h-6 text-white" />
          </div>
          <div class="ml-4 flex-1">
            <p class="text-sm font-medium text-ui-600"><%= @title %></p>
            <p class="text-2xl font-bold text-ui-900"><%= @value %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp stat_color_class("blue"), do: "bg-blue-500"
  defp stat_color_class("green"), do: "bg-green-500"
  defp stat_color_class("yellow"), do: "bg-yellow-500"
  defp stat_color_class("red"), do: "bg-rose-500"
  defp stat_color_class(_), do: "bg-ui-500"
end
