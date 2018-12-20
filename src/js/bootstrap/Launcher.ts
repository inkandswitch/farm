import Repo from "../Repo"
import * as Bs from "."

export function data(repo: Repo) {
  return repo.create({
    gizmos: [
      {
        code: Bs.code(repo, "CounterTutorial.elm", {
          title: "Counter Tutorial",
          icon: Bs.assetDataUrl("tutorial_icon.png"),
        }),
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
  const title = Bs.code(repo, "Title.elm")
  const editableTitle = Bs.code(repo, "EditableTitle.elm")
  const avatar = Bs.code(repo, "SimpleAvatar.elm")

  return Bs.code(repo, "Launcher.elm", {
    title: "Launcher",
    icon: Bs.assetDataUrl("create_icon.png"),
    config: {
      createIcon: Bs.assetDataUrl("create_gizmo_icon.png"),
      title,
      editableTitle,
      avatar,
      icon: Bs.code(repo, "Icon.elm", {
        config: {
          defaultIcon: Bs.assetDataUrl("default_gizmo_icon.png"),
        },
      }),
      note: Bs.code(repo, "Note.elm", {
        title: "Note",
        icon: Bs.assetDataUrl("note_icon.png"),
      }),
      imageGallery: Bs.code(repo, "SimpleImageGallery.elm", {
        title: "Simple Image Gallery",
        icon: Bs.assetDataUrl("image_gallery_icon.png"),
      }),
      // todo: Bs.code(repo, "Todos.elm", {
      //   title: "Todos",
      //   icon: Bs.assetDataUrl("todo_icon.png")
      // }),
      chat: Bs.code(repo, "Chat.elm", {
        title: "Chat",
        icon: Bs.assetDataUrl("chat_icon.png"),
        config: {
          editableTitle,
          avatar
        },
      }),
    },
  })
}
