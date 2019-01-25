import Repo from "../Repo"
import * as Bs from "."
import * as Workspace from "./Workspace"

export function data(repo: Repo) {
  return repo.create({
    "@ink": {
      avatar: Bs.code(repo, "SimpleAvatar.elm"),
      board: Bs.code(repo, "Board.elm"),
      chat: Bs.code(repo, "Chat.elm"),
      editableTitle: Bs.code(repo, "EditableTitle.elm"),
      historyViewer: Bs.code(repo, "HistoryViewer.elm"),
      image: Bs.code(repo, "Image.elm"),
      liveEdit: Bs.code(repo, "LiveEdit.elm"),
      navigationBar: Bs.code(repo, "NavigationBar.elm"),
      note: Bs.code(repo, "Note.elm"),
      property: Bs.code(repo, "Property.elm"),
      superboxDefault: Bs.code(repo, "SuperboxDefault.elm"),
      superboxEdit: Bs.code(repo, "SuperboxEdit.elm"),
      todoList: Bs.code(repo, "TodoList.elm"),
      workspace: Workspace.code(repo),
      icons: {
        chat: Bs.assetDataUrl(repo, "chat_icon.png"),
        tutorial: Bs.assetDataUrl(repo, "tutorial_icon.png"),
      },
    },
  })
}
