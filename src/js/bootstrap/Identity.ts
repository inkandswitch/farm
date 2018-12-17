import Repo from "../Repo"

export function data(repo: Repo) {
  return repo.create({
    title: "Mysterious Stranger",
  })
}
