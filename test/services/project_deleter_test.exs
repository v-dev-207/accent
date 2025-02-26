defmodule AccentTest.ProjectDeleter do
  use Accent.RepoCase

  alias Accent.{Collaborator, Project, ProjectDeleter, Repo}

  test "create with language and user" do
    project = %Project{main_color: "#f00", name: "french"} |> Repo.insert!()
    collaborator = %Collaborator{project_id: project.id, role: "reviewer"} |> Repo.insert!()

    assert project
           |> Ecto.assoc(:all_collaborators)
           |> Repo.all()
           |> Enum.map(& &1.id) === [collaborator.id]

    {:ok, project} = ProjectDeleter.delete(project: project)

    assert Repo.all(Ecto.assoc(project, :all_collaborators)) === []
  end
end
