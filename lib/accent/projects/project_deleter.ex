defmodule Accent.ProjectDeleter do
  alias Accent.Repo

  def delete(project: project) do
    project
    |> Ecto.assoc(:all_collaborators)
    |> Repo.delete_all()

    {:ok, project}
  end
end
