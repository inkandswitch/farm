import Repo from "../Repo"
import * as Bs from "."
import * as RealmUrl from "../RealmUrl"

export function code(repo: Repo) {
  return Bs.code(repo, "Workspace.elm", {
    title: "Workspace",
    config: {
      navigationBar: Bs.code(repo, "NavigationBar.elm"),
    },
  })
}

export function data(repo: Repo) {
  const note = Bs.code(repo, "Note.elm")
  const todoList = Bs.code(repo, "TodoList.elm")

  const editableTitle = Bs.code(repo, "EditableTitle.elm")
  const avatar = Bs.code(repo, "SimpleAvatar.elm")
  const chat = Bs.code(repo, "Chat.elm", {
    title: "Chat",
    icon: Bs.assetDataUrl("chat_icon.png"),
    config: {
      editableTitle,
      avatar,
    },
  })

  const board = Bs.code(repo, "Board.elm", {
    config: {
      chat,
      note,
      todoList,
    },
  })

  const boardData = repo.create({
    cards: [
      {
        code: note,
        data: repo.create({
          title: "Welcome to Realmpin",
          body: "Right-click to add things to the board.",
        }),
        x: 50,
        y: 50,
        w: 300,
        h: 400,
        z: 0,
      },
    ],
  })

  return repo.create({
    history: {
      backward: [RealmUrl.create({ code: board, data: boardData })],
      forward: [],
    },
  })
}
