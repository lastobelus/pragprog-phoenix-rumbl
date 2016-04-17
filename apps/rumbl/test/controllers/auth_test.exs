defmodule Rumbl.AuthTest do
  use Rumbl.ConnCase
  alias Rumbl.Auth

  # Some special considerations to do unit testing of Router pipeline plugs

  setup %{conn: conn} do
    conn =
      conn
      # bypass_through sends a connection through the Endpoint,
      # Router, and desired pipelines, but bypasses the route dispatch.
      # The result is a connection wired with all the transformations
      # plugs expect, like fetching the session, adding flash messages etc.
      |> bypass_through(Rumbl.Router, :browser)
      # after calling bypass_through, calling requests will simply store
      # the request path in the conn without dispatching it
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "authenticate_user halts when no current_user exists", %{conn: conn} do
    conn = Auth.authenticate_user(conn, [])
    assert conn.halted
  end

  test "authenticate_user continues when the current_user exists", %{conn: conn} do
    conn = conn
    |> assign(:current_user, %Rumbl.User{})
    |> Auth.authenticate_user([])

    refute conn.halted
  end

  test "login puts the user in the session", %{conn: conn} do
    login_conn = conn
    |> Auth.login(%Rumbl.User{id: 123})
    # after using bypass_through, we can use send_resp to simulate
    # sending the response to the client with a given status & body.
    # We can then make a new request with that connection
    |> send_resp(:ok, "")

    next_conn = get(login_conn, "/")
    assert get_session(next_conn, :user_id) == 123
  end

  test "logout drops the session", %{conn: conn} do
    logout_conn = conn
    |> put_session(:user_id, 123)
    |> Auth.logout()
    |> send_resp(:ok, "")

    next_conn = get(logout_conn, "/")
    refute get_session(next_conn, :user_id)
  end

  test "call places user from session into assigns", %{conn: conn} do
    user = insert_user()

    conn =
      conn
      |> put_session(:user_id, user.id)
      |> Auth.call(Repo)

    assert conn.assigns.current_user.id == user.id
  end

  test "call with no session sets current_user assign to nil", %{conn: conn} do
    conn = conn
    |> Auth.call(Repo)

    assert conn.assigns.current_user == nil
  end

  test "login with a valid email and pass", %{conn: conn} do
    user = insert_user(username: "valid", password: "pass1234")

    {:ok, conn} = Auth.login_by_username_and_password(conn, "valid", "pass1234", repo: Repo)

    assert conn.assigns.current_user.id == user.id
  end

  test "login with a not found user", %{conn: conn} do
    assert {:error, :not_found, _conn} = Auth.login_by_username_and_password(conn, "valid", "pass1234", repo: Repo)
  end

  test "login with password mismatch", %{conn: conn} do
    user = insert_user(username: "valid", password: "pass1234")
    assert {:error, :unauthorized, _conn} = Auth.login_by_username_and_password(conn, "valid", "wrong", repo: Repo)
  end

end