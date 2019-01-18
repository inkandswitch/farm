import Repo from "../Repo"
import * as Bs from "."

export function code(repo: Repo) {
  return Bs.code(repo, "Workspace.elm", {
    title: "Workspace",
    config: {
        navigationBar: Bs.code(repo, "NavigationBar.elm")
    },
  })
}

export function data(repo: Repo) {
   const dummyBoard = Bs.code(repo, "Board.elm")
   const dummyData1 = repo.create()
   const dummyData2 = repo.create()
   return repo.create({
       history: [
           {
               code: dummyBoard,
               data: dummyData1
           },
           {
               code: dummyBoard,
               data: dummyData2
           }
        ]
   })
}