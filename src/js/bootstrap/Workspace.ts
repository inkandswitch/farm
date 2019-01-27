import Repo from "../Repo"
import * as Bs from "."

export function code(repo: Repo) {
  return workspace(repo)
}

export function data(repo: Repo) {
  return workspaceData(repo)
}

export function avatar(repo: Repo) {
  return Bs.code(repo, "SimpleAvatar.elm")
}

export function board(repo: Repo) {
  const url = Bs.code(repo, "Board.elm", {
    config: {
      chat: chat(repo),
      note: note(repo),
      todoList: todoList(repo),
    },
  })

  // Add board link to itself
  repo.change(url, (state: any) => {
    state.config.board = url
  })

  return url
}

export function chat(repo: Repo) {
  return Bs.code(repo, "Chat.elm")
}

export function counter(repo: Repo) {
  return Bs.code(repo, "Counter.elm")
}

export function counterData(repo: Repo) {
  return repo.create({ title: "Counter data" })
}

export function counterTutorial(repo: Repo) {
  return Bs.code(repo, "CounterTutorial.elm")
}

export function counterTutorialData(repo: Repo) {
  return repo.create({
    title: "Counter Tutorial",
    step: 1,
    codeUrl: counter(repo),
    dataUrl: counterData(repo),
  })
}

export function editableTitle(repo: Repo) {
  return Bs.code(repo, "EditableTitle.elm")
}

export function historyViewer(repo: Repo) {
  return Bs.code(repo, "HistoryViewer.elm", {
    config: {
      property: property(repo),
    },
  })
}

export function identityData(repo: Repo) {
  return repo.create({
    title: "Mysterious Stranger",
  })
}

export function image(repo: Repo) {
  return Bs.code(repo, "Image.elm")
}

export function liveEdit(repo: Repo) {
  return Bs.code(repo, "LiveEdit.elm")
}

export function navigationBar(repo: Repo) {
  return Bs.code(repo, "NavigationBar.elm")
}

export function note(repo: Repo) {
  return Bs.code(repo, "Note.elm")
}

export function property(repo: Repo) {
  return Bs.code(repo, "Property.elm")
}

export function registryData(repo: Repo) {
  return repo.create({
    avatar: avatar(repo),
    board: board(repo),
    chat: chat(repo),
    editableTitle: editableTitle(repo),
    historyViewer: historyViewer(repo),
    image: image(repo),
    liveEdit: liveEdit(repo),
    navigationBar: navigationBar(repo),
    note: note(repo),
    property: property(repo),
    superboxDefault: superboxDefault(repo),
    superboxEdit: superboxEdit(repo),
    todoList: todoList(repo),
    workspace: workspace(repo),
    icons: {
      chat: chatIcon(repo),
      tutorial: tutorialIcon(repo),
    },
  })
}

export function superboxDefault(repo: Repo) {
  return Bs.code(repo, "SuperboxDefault.elm")
}

export function superboxEdit(repo: Repo) {
  return Bs.code(repo, "SuperboxEdit.elm")
}

export function todoList(repo: Repo) {
  return Bs.code(repo, "TodoList.elm")
}

export function wiki(repo: Repo) {
  return Bs.code(repo, "Wiki.elm", {
    title: "Wiki",
    config: {
      article: Bs.code(repo, "Article.elm"),
      articleIndex: Bs.code(repo, "ArticleIndex.elm", {
        config: {
          articleIndexItem: Bs.code(repo, "ArticleIndexItem.elm"),
        },
      }),
    },
  })
}

export function wikiData(repo: Repo) {
  const wikiArticle = repo.create({
    title: "Welcome",
    body: "This is the FarmWiki",
  })

  return repo.create({
    title: "FarmWiki",
    articles: [wikiArticle],
  })
}

export function windowManager(repo: Repo) {
  return Bs.code(repo, "WindowManager.elm", {
    config: {
      title: editableTitle(repo),
      empty: Bs.code(repo, "EmptyGizmo.elm"),
    },
  })
}

export function windowManagerData(repo: Repo) {
  return repo.create({
    windows: [
      {
        x: 20,
        y: 20,
        w: 300,
        h: 400,
        z: 0,
        code: counterTutorial(repo),
        data: counterTutorialData(repo),
      },
    ],
  })
}

export function workspace(repo: Repo) {
  return Bs.code(repo, "Workspace.elm", {
    config: {
      board: board(repo),
      liveEdit: liveEdit(repo),
      historyViewer: historyViewer(repo)
    },
  })
}

export function workspaceData(repo: Repo) {
  return repo.create({
    history: {
      backward: [],
      forward: [],
      seen: [],
    },
  })
}

export function chatIcon(repo: Repo) {
  return Bs.asset(repo, "chat_icon.png")
}

export function tutorialIcon(repo: Repo) {
  return Bs.asset(repo, "tutorial_icon.png")
}
