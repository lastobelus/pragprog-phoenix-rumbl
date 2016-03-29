defmodule Rumbl.VideoControllerTest do
  use Rumbl.ConnCase
  alias Rumbl.Video

  @valid_attrs %{url: "http://youtu.be", title: "Valid Title", description: "Valid Description"}
  @invalid_attrs %{title: "Invalid"}

  defp video_count(query), do: Repo.one(from v in query, select: count(v.id))

  setup %{conn: conn} = config do
    if username = config[:login_as] do
      user = insert_user(username: username)
      conn = assign(conn, :current_user, user)
      {:ok, conn: conn, user: user}
    else
      :ok
    end
  end

  @tag login_as: "max"
  test "creates user video and redirects", %{conn: conn, user: user} do
    conn = post conn, video_path(conn, :create), video: @valid_attrs
    assert redirected_to(conn) == video_path(conn, :index)
    assert Repo.get_by!(Video, @valid_attrs).user_id == user.id
  end

  @tag login_as: "max"
  test "does not create video and renders error when invalid", %{conn: conn} do
    count_before = video_count(Video)
    conn = post conn, video_path(conn, :create), video: @invalid_attrs
    assert html_response(conn, 200) =~ "check the errors"
    assert video_count(Video) == count_before
  end

  @tag login_as: "max"
  test "lists all user's videos on index", %{conn: conn, user: user} do
    user_video_one = insert_video(user, title: "max title one")
    user_video_two = insert_video(user, title: "max title two")
    other_user_video_one = insert_video(insert_user(username: "other"), title: "other title one")

    conn = get(conn, video_path(conn, :index))

    assert html_response(conn, 200) =~ ~r/Listing Videos/i
    assert String.contains?(conn.resp_body, user_video_one.title)
    assert String.contains?(conn.resp_body, user_video_two.title)

    refute String.contains?(conn.resp_body, other_user_video_one.title)
  end

  @tag login_as: "max"
  test "edits shows video edit page", %{conn: conn, user: user} do
    video = insert_video(user, @valid_attrs)

    conn = get(conn, video_path(conn, :edit, video.id))

    assert html_response(conn, 200) =~ ~r/Edit video.*#{video.title}/s
  end

  @tag login_as: "max"
  test "updates existing video and redirects", %{conn: conn, user: user} do
    video = insert_video(user, @valid_attrs)

    conn = put(conn, video_path(conn, :update, video), video: %{title: "new title"})

    # assert html_response(conn, 302)
    assert redirected_to(conn) == video_path(conn, :show, video.id)
    assert Repo.get(Video, video.id).title == "new title"
  end

  @tag login_as: "max"
  test "does not update invalid video", %{conn: conn, user: user} do
    video = insert_video(user, @valid_attrs)

    conn = put(conn, video_path(conn, :update, video), video: %{title: ""})

    assert html_response(conn, 200) =~ "check the errors"
    assert Repo.get(Video, video.id).title == video.title
  end

  @tag login_as: "max"
  test "deletes existing video", %{conn: conn, user: user} do
    video = insert_video(user, @valid_attrs)

    conn = delete conn, video_path(conn, :delete, video)
    assert redirected_to(conn) == video_path(conn, :index)
    refute Repo.get(Video, video.id)
  end

  test "requires user authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, video_path(conn, :new)),
      get(conn, video_path(conn, :index)),
      get(conn, video_path(conn, :show, "123")),
      get(conn, video_path(conn, :edit, "123")),
      put(conn, video_path(conn, :update, "123", %{})),
      post(conn, video_path(conn, :create, %{})),
      delete(conn, video_path(conn, :delete, "123")),
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end


end