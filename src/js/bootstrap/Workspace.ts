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
   const dummyBoard = Bs.code(repo, "DummyBoard.elm")
   const dummyData1 = repo.create({content: "1"})
   const dummyData2 = repo.create({content: "2"})
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