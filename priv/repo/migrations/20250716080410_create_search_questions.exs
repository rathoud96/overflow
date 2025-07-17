defmodule Overflow.Repo.Migrations.CreateSearchQuestions do
  use Ecto.Migration

  def change do
    create table(:search_questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create index(:search_questions, [:user_id])
    create index(:search_questions, [:inserted_at])
  end
end
