import Repo from "../Repo"
import * as Bs from "."


export function code(repo: Repo) {
  const note = Bs.code(repo, "Note.elm")
  const todoList = Bs.code(repo, "TodoList.elm")

  const editableTitle = Bs.code(repo, "EditableTitle.elm")
  const avatar = Bs.code(repo, "SimpleAvatar.elm")
  const image = Bs.code(repo, "Image.elm")

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
      image,
      note,
      todoList,
    },
  })

  repo.change(board, (doc: any) => {
    doc.config.board = board
  })

  return Bs.code(repo, "Workspace.elm", {
    title: "Workspace",
    config: {
      navigationBar: Bs.code(repo, "NavigationBar.elm"),
      board: board
    },
  })
}

export function data(repo: Repo) {
  return repo.create({
    history: {
      backward: [],
      forward: [],
    },
  })
}
