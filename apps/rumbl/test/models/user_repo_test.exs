defmodule Rumbl.UserRepoTest do
  use Rumbl.ModelCase, async: false
  alias Rumbl.User

  @valid_attrs %{name: "A User", username: "a_user", password: "password"}
  @invalid_attrs %{}

  test "converts unique constraint on username to error" do
    insert_user(username: "first")
    attrs = Map.put(@valid_attrs, :username, "first")
    changeset = User.changeset(%User{}, attrs)

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:username, "has already been taken"} in changeset.errors
  end
end