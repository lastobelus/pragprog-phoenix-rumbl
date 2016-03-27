defmodule Rumbl.Video do
  use Rumbl.Web, :model

  schema "videos" do
    field :url, :string
    field :title, :string
    field :description, :string

    belongs_to :user, Rumbl.User
    belongs_to :category, Rumbl.Category

    timestamps
  end

  @required_fields ~w(url title description)
  @optional_fields ~w(category_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    # this asserts that category_id refers to a category_id that exists
    # in the categories table, via the foreign_key database constraint
    # that the `add :category_id, references(:categories) migration` creates for us
    |> assoc_constraint(:category)
  end
end
