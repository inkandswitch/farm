import Repo from "../Repo"
import * as Bs from "."

export function code(repo: Repo) {
  return Bs.code(repo, "Workspace.elm")
}

export function data(repo: Repo) {
  return repo.create({
    history: {
      backward: [],
      forward: [],
      seen: [],
    },
  })
}
