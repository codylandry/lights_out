defmodule LightsOut.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :code, :string

      timestamps(type: :utc_datetime)
    end
  end
end
