defmodule SummerChallenge.Repo.Migrations.AddProfileImageUrlToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :profile_image_url, :string
    end
  end
end
