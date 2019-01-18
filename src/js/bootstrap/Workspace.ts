import Repo from "../Repo"
import * as Bs from "."
import * as RealmUrl from "../RealmUrl"

export function code(repo: Repo) {
  return Bs.code(repo, "Workspace.elm", {
    title: "Workspace",
    config: {
        navigationBar: Bs.code(repo, "NavigationBar.elm")
    },
  })
}

export function data(repo: Repo) {
   const board = Bs.code(repo, "Board.elm")
   const dummyData1 = repo.create()
   const dummyData2 = repo.create()
   return repo.create({
       history: {
           backward: [
               RealmUrl.create({ code: board, data: dummyData1 }),
               RealmUrl.create({ code: board, data: dummyData2 }),
           ],
           forward: []
       }
   })
}