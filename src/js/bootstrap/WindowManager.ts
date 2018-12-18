import Repo from "../Repo"
import * as Bs from "."

export function data(repo: Repo) {
  return repo.create({
    windows: [
      {
        x: 20,
        y: 20,
        w: 300,
        h: 400,
        z: 0,
        code: Bs.code(repo, "CounterTutorial.elm"),
        data: repo.create({
          title: "Counter Tutorial",
          step: 1,
          codeUrl: Bs.code(repo, "Counter.elm"),
          dataUrl: repo.create({ title: "Counter data" }),
        }),
      },
    ],
  })
}

export function code(repo: Repo) {
  return Bs.code(repo, "WindowManager.elm", {
    title: "WindowManager code",
    config: {
      title: Bs.code(repo, "Title.elm"),
      empty: Bs.code(repo, "EmptyGizmo.elm"),
    },
  })
}
