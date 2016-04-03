defmodule Rumbl.User do
  use Rumbl.Web, :model
  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    has_many :videos, Rumbl.Video
    has_many :annotations, Rumbl.Annotation

    timestamps
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(name username), [])
    |> validate_length(:username, min: 1, max: 20)
    # unlike validates_uniqueness_of in Rails, this works directly together
    # with the unique index on username we defined in our migration, and is
    # actually concurrent-safe (to the point that the database is), AND
    # it automatically converts into a normal validation error for us --
    # no special handling needed
    |> unique_constraint(:username)
  end

  # diffferent validation strategies, and/or combinations
  # of optional/required fields are accomplished simply
  # by defining different changeset functions
  def registration_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> cast(params, ~w(password), [])
    # persistence is not strongly coupled to our change policies!
    # so we can validate virtual fields the same as we validate
    # database attributes
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))

      _ ->
        changeset
    end
  end
end