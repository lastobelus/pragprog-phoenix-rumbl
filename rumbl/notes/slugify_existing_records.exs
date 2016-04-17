alias Rumbl.Repo
alias Rumbl.Video
import Ecto.Changeset

for video <- Repo.all(Video) do
  changeset = Video.changeset(video, %{})
  changeset = put_change(changeset, :slug, Video.slugify(video.title))

  Repo.update!(changeset)
end
