defmodule Accent.GraphQL.Resolvers.Lint do
  require Ecto.Query

  import Absinthe.Resolution.Helpers, only: [batch: 3]

  alias Accent.Scopes.Revision, as: RevisionScope
  alias Accent.Scopes.Translation, as: TranslationScope

  alias Accent.{
    Language,
    Plugs.GraphQLContext,
    Repo,
    Translation
  }

  @spec lint_translation(Translation.t(), map(), GraphQLContext.t()) :: {:ok, Paginated.t(Language.Entry.t())}
  def lint_translation(translation, args, resolution) do
    batch({__MODULE__, :preload_translations}, translation, fn batch_results ->
      translation = Map.get(batch_results, translation.id)
      lint_batched_translation(translation, args, resolution)
    end)
  end

  def lint_batched_translation(translation, args, _) do
    translation = overwrite_text_args(translation, args)
    language_slug = translation.revision.slug || translation.revision.language.slug
    entry = Translation.to_langue_entry(translation, translation.master_translation, translation.revision.master, language_slug)
    [{_, messages}] = Accent.Lint.lint([entry])

    {:ok, messages}
  end

  def preload_translations(_, translations = [translation | _]) do
    translations = Repo.preload(translations, revision: :language)

    project =
      translation
      |> Ecto.assoc(:project)
      |> Repo.one()

    master_revision =
      project
      |> Ecto.assoc(:revisions)
      |> RevisionScope.master()
      |> Repo.one()

    master_translations =
      Accent.Translation
      |> TranslationScope.from_project(project.id)
      |> TranslationScope.from_revision(master_revision.id)
      |> TranslationScope.active()
      |> Repo.all()
      |> Enum.map(&{{&1.key, &1.document_id}, &1})
      |> Enum.into(%{})

    Enum.reduce(translations, %{}, fn translation, acc ->
      master_translation = Map.get(master_translations, {translation.key, translation.document_id})
      Map.put(acc, translation.id, %{translation | master_translation: master_translation})
    end)
  end

  defp overwrite_text_args(translation, %{text: text}) when is_binary(text) do
    %{translation | corrected_text: text}
  end

  defp overwrite_text_args(translation, _) do
    translation
  end
end
