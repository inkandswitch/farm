import Repo from "./Repo"
import { readFileSync } from "fs"
import path from "path"
import Compiler from "./Compiler"
import * as Gizmo from "./Gizmo"
import * as GizmoWindow from "./GizmoWindow"

// make the web worker thread-safe:
;(<any>process).dlopen = () => {
  throw new Error("Load native module is not thread-safe")
}

export default class App {
  repo = new Repo("./repo.worker.js")
  compiler: Compiler = new Compiler(this.repo, "./compile.worker.js")
  root: any

  rootDataUrl: string = load("rootDataUrl", () =>
    this.repo.create({
      title: "Navigator data",
      history: [
        {
          code: this.bootstrapWidget("Launcher.elm", {
            icon: this.bootstrapWidget("Icon.elm", {}),
            title: this.bootstrapWidget("Title.elm", {}),
            note: this.bootstrapWidget("Note.elm", {}),
            imageGallery: this.bootstrapWidget("SimpleImageGallery.elm", {})
          }),
          data: this.repo.create(),
          // code: this.bootstrapWidget("CounterTutorial.elm"),
          // data: this.repo.create({
          //   title: "CounterTutorial data",
          //   step: 1,
          //   codeUrl: this.bootstrapWidget("Counter.elm"),
          //   dataUrl: this.repo.create({ title: "Counter data" }),
          // }),
        },
      ],
    }),
  )

  rootCodeUrl: string = load("rootCodeUrl", () =>
    this.bootstrapWidget("Navigator.elm"),
  )

  selfDataUrl: string = load("selfDataUrl", () =>
    this.repo.create({
      title: "Mysterious Stranger",
    }),
  )

  constructor() {
    ;(self as any).repo = this.repo
    Gizmo.setRepo(this.repo)
    Gizmo.setCompiler(this.compiler)
    Gizmo.setSelfDataUrl(this.selfDataUrl)

    customElements.define("realm-ui", Gizmo.constructorForWindow(window))
    customElements.define(
      "realm-window",
      GizmoWindow.constructorForWindow(window),
    )

    const style = document.createElement("style")
    style.innerHTML = `
      * {
        box-sizing: border-box;
      }

      html, body, div, span, applet, object, iframe,
      h1, h2, h3, h4, h5, h6, p, blockquote, pre,
      a, abbr, acronym, address, big, cite, code,
      del, dfn, em, font, img, ins, kbd, q, s, samp,
      small, strike, strong, sub, sup, tt, var,
      dl, dt, dd, ol, ul, li,
      fieldset, form, label, legend,
      table, caption, tbody, tfoot, thead, tr, th, td {
        margin: 0;
        padding: 0;
        border: 0;
        outline: 0;
        font-weight: inherit;
        font-style: inherit;
        font-size: 100%;
        font-family: inherit;
        vertical-align: baseline;
      }
      /* remember to define focus styles! */
      :focus {
        outline: 0;
      }
      body {
        line-height: 1;
        color: black;
        background: white;
      }
      ol, ul {
        list-style: none;
      }
      /* tables still need 'cellspacing="0"' in the markup */
      table {
        border-collapse: separate;
        border-spacing: 0;
      }
      caption, th, td {
        text-align: left;
        font-weight: normal;
      }
      blockquote:before, blockquote:after,
      q:before, q:after {
        content: "";
      }
      blockquote, q {
        quotes: "" "";
      }

      realm-ui {
        display: contents;
      }
    `
    document.body.appendChild(style)

    this.root = document.createElement("realm-ui")
    this.root.setAttribute("code", this.rootCodeUrl)
    this.root.setAttribute("data", this.rootDataUrl)
    document.body.appendChild(this.root)
  }

  handleUrl(url: string) {
    this.root.navigateTo(url)
  }

  bootstrapWidget(file: string, config: { [k: string]: string } = {}): string {
    return this.repo.create({
      title: `${file} code`,
      "Source.elm": sourceFor(file),
      config,
    })
  }
}

function sourceFor(name: string) {
  return readFileSync(path.resolve(`src/elm/examples/${name}`)).toString()
}

function load(key: string, def: () => string): string {
  if (localStorage[key]) return localStorage[key]
  const value = def()
  localStorage[key] = value
  return value
}
