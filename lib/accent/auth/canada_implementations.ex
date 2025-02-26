defimpl Canada.Can, for: Accent.User do
  alias Accent.{User, Project, Comment}

  def can?(%User{permissions: permissions}, action, project_id) when is_binary(project_id) do
    validate_role(permissions, action, project_id)
  end

  def can?(%User{permissions: permissions}, action, project = %Project{}) do
    validate_role(permissions, action, project)
  end

  def can?(%User{id: user_id}, _action, %Comment{user_id: comment_user_id}) do
    user_id == comment_user_id
  end

  def can?(%User{email: email}, action, _) do
    Accent.EmailAbilities.can?(email, action)
  end

  def can?(_user, _action, nil), do: false

  def validate_role(nil, _action, _project_id), do: false

  def validate_role(permissions, action, project = %Project{}) do
    permissions
    |> Map.get(project.id)
    |> Accent.RoleAbilities.can?(action, project)
  end

  def validate_role(permissions, action, project_id) do
    permissions
    |> Map.get(project_id)
    |> Accent.RoleAbilities.can?(action)
  end
end
