import Repo from "../Repo"
import * as Bs from "."
import * as Wiki from "./Wiki"

export function data(repo: Repo) {
  const counterCode = Bs.code(repo, "CounterTutorial.elm", {
    title: "Counter Tutorial",
    icon: Bs.assetDataUrl(repo, "tutorial_icon.png"),
  })
  const counterData = repo.create({
    title: "Counter Tutorial",
    step: 1,
    codeUrl: Bs.code(repo, "Counter.elm"),
    dataUrl: repo.create({ title: "Counter data" }),
  })

  const noteData = repo.create({
    title: "First Note!",
    body: "This is my first note!",
  })

  const wikiData = Wiki.data(repo)

  const note = Bs.code(repo, "Note.elm", {
    title: "Note",
    icon: Bs.assetDataUrl(repo, "note_icon.png"),
  })
  const imageGallery = Bs.code(repo, "SimpleImageGallery.elm", {
    title: "Simple Image Gallery",
    icon: Bs.assetDataUrl(repo, "image_gallery_icon.png"),
  })
  const wiki = Wiki.code(repo)
  const editableTitle = Bs.code(repo, "EditableTitle.elm")
  const avatar = Bs.code(repo, "SimpleAvatar.elm")
  const chat = Bs.code(repo, "Chat.elm", {
    title: "Chat",
    icon: Bs.assetDataUrl(repo, "chat_icon.png"),
    config: {
      editableTitle,
      avatar,
    },
  })
  return repo.create({
    gizmos: [
      { code: counterCode, data: counterData },
      { code: note, data: noteData },
      { code: wiki, data: wikiData },
    ],
    sources: [note, imageGallery, chat, counterCode, wiki],
    data: [counterData, noteData],
  })
}

export function code(repo: Repo) {
  const title = Bs.code(repo, "Title.elm")
  const editableTitle = Bs.code(repo, "EditableTitle.elm")
  const avatar = Bs.code(repo, "SimpleAvatar.elm")

  return Bs.code(repo, "Launcher.elm", {
    title: "Launcher",
    icon: Bs.assetDataUrl(repo, "create_icon.png"),
    config: {
      createIcon: Bs.assetDataUrl(repo, "create_gizmo_icon.png"),
      title,
      editableTitle,
      avatar,
      icon: Bs.code(repo, "Icon.elm", {
        config: {
          defaultIcon: Bs.assetDataUrl(repo, "default_gizmo_icon.png"),
        },
      }),
    },
  })
}
