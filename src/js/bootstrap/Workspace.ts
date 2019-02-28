import Repo from "../Repo"
import * as Bs from "."

export function code(identity: string, repo: Repo) {
  return workspace(identity, repo)
}

export function data(identity: string, repo: Repo) {
  return workspaceData(identity, repo)
}

export function article(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Article.elm")
}

export function titledMarkdownNote(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "TitledMarkdownNote.elm")
}

export function koala(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Koala.elm", {
    property: property(identity, repo),
    note: titledMarkdownNote(identity, repo)
  })
}

export function smallAvatar(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "SmallAvatar.elm")
}

export function pickerItem(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "PickerItem.elm", {
    config: {
      property: property(identity, repo),
      authors: authors(identity, repo),
    },
  })
}

export function authors(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Authors.elm", {
    config: {
      smallAvatar: smallAvatar(identity, repo),
    },
  })
}

export function avatar(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "SimpleAvatar.elm")
}

export function board(identity: string, repo: Repo) {
  const url = Bs.code(identity, repo, "Board.elm", {
    title: "Board",
    config: {
      chat: chat(identity, repo),
      note: note(identity, repo),
      koala: koala(identity, repo),
      todoList: todoList(identity, repo),
      image: image(identity, repo),
      dotGrid: Bs.asset(repo, "dot_grid.svg"),
    },
  })

  // Add board link to itself
  repo.change(url, (state: any) => {
    state.config.board = url
  })

  return url
}

export function chat(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Chat.elm", {
    title: "Chat",
    config: {
      avatar: avatar(identity, repo),
      editableTitle: editableTitle(identity, repo),
    },
  })
}

export function counter(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Counter.elm")
}

export function counterData(identity: string, repo: Repo) {
  return repo.create({ title: "Counter data" })
}

export function counterTutorial(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "CounterTutorial.elm")
}

export function counterTutorialData(identity: string, repo: Repo) {
  return repo.create({
    title: "Counter Tutorial",
    step: 1,
    codeUrl: counter(identity, repo),
    dataUrl: counterData(identity, repo),
  })
}

export function editableTitle(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "EditableTitle.elm")
}

export function historyViewer(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "HistoryViewer.elm", {
    config: {
      property: property(identity, repo),
      authors: authors(identity, repo),
    },
  })
}

export function createPicker(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "CreatePicker.elm", {
    config: {
      property: property(identity, repo),
      pickerItem: pickerItem(identity, repo),
    },
  })
}

export function rendererPicker(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "RendererPicker.elm", {
    config: {
      property: property(identity, repo),
      pickerItem: pickerItem(identity, repo),
    },
  })
}

export function gizmoTemplate(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "GizmoTemplate.elm", {
    title: "My Gizmo",
    config: {
      avatar: avatar(identity, repo),
      authors: authors(identity, repo),
      editableTitle: editableTitle(identity, repo),
    }
  })
}

export function identityData(repo: Repo) {
  const identity = repo.create({
    title: "Mysterious Stranger",
  })
  repo.change(identity, (doc: any) => {
    doc.authors = [identity]
  })
  return identity
}

export function image(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Image.elm")
}

export function liveEdit(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "LiveEdit.elm")
}

export function navigationBar(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "NavigationBar.elm")
}

export function note(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Note.elm", {
    title: "Note",
  })
}

export function property(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Property.elm")
}

export function registryData(identity: string, repo: Repo) {
  return repo.create({
    authors: authors(identity, repo),
    avatar: avatar(identity, repo),
    board: board(identity, repo),
    chat: chat(identity, repo),
    koala: koala(identity, repo),
    titledMarkdownNote: titledMarkdownNote(identity, repo),
    editableTitle: editableTitle(identity, repo),
    historyViewer: historyViewer(identity, repo),
    rendererPicker: rendererPicker(identity, repo),
    createPicker: createPicker(identity, repo),
    image: image(identity, repo),
    liveEdit: liveEdit(identity, repo),
    navigationBar: navigationBar(identity, repo),
    note: note(identity, repo),
    pickerItem: property(identity, repo),
    property: property(identity, repo),
    smallAvatar: smallAvatar(identity, repo),
    superboxDefault: superboxDefault(identity, repo),
    superboxEdit: superboxEdit(identity, repo),
    todoList: todoList(identity, repo),
    workspace: workspace(identity, repo),
    icons: {
      chat: chatIcon(repo),
      tutorial: tutorialIcon(repo),
    },
  })
}

export function superboxDefault(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "SuperboxDefault.elm")
}

export function superboxEdit(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "SuperboxEdit.elm")
}

export function todoList(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "TodoList.elm", {
    title: "Todo List",
  })
}

export function wiki(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Wiki.elm", {
    title: "Wiki",
    config: {
      article: article(identity, repo),
      articleIndex: Bs.code(identity, repo, "ArticleIndex.elm", {
        config: {
          articleIndexItem: Bs.code(identity, repo, "ArticleIndexItem.elm"),
        },
      }),
    },
  })
}

export function wikiData(identity: string, repo: Repo) {
  const wikiArticle = repo.create({
    title: "Welcome",
    body: "This is the FarmWiki",
  })

  return repo.create({
    title: "FarmWiki",
    articles: [wikiArticle],
  })
}

export function windowManager(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "WindowManager.elm", {
    config: {
      title: editableTitle(identity, repo),
      empty: Bs.code(identity, repo, "EmptyGizmo.elm"),
    },
  })
}

export function windowManagerData(identity: string, repo: Repo) {
  return repo.create({
    windows: [
      {
        x: 20,
        y: 20,
        w: 300,
        h: 400,
        z: 0,
        code: counterTutorial(identity, repo),
        data: counterTutorialData(identity, repo),
      },
    ],
  })
}

export function workspace(identity: string, repo: Repo) {
  return Bs.code(identity, repo, "Workspace.elm", {
    config: {
      board: board(identity, repo),
      liveEdit: liveEdit(identity, repo),
      openPicker: historyViewer(identity, repo),
      rendererPicker: rendererPicker(identity, repo),
      createPicker: createPicker(identity, repo),
      property: property(identity, repo),
      gizmoTemplate: gizmoTemplate(identity, repo),
    },
  })
}

export function workspaceData(identity: string, repo: Repo) {
  return repo.create({
    codeDocs: [
      board(identity, repo),
      note(identity, repo),
      chat(identity, repo),
      todoList(identity, repo),
    ],
  })
}

export function chatIcon(repo: Repo) {
  return Bs.asset(repo, "chat_icon.png")
}

export function tutorialIcon(repo: Repo) {
  return Bs.asset(repo, "tutorial_icon.png")
}
