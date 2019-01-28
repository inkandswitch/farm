type ExtensionPanel = chrome.devtools.panels.ExtensionPanel

createPanelIfRepo()

chrome.devtools.network.onNavigated.addListener(() => {
  createPanelIfRepo()
})

let panelCreated = false
async function createPanelIfRepo() {
  if (panelCreated) return

  const hasRepo = await evalIn("main", `"repo" in window`)

  if (!hasRepo || panelCreated) return
  const panel = await createPanel("Hypermerge", "index.html")
  panelCreated = true
}

function evalIn(ctx: "main" | "worker", expr: string): Promise<any> {
  return new Promise((res, rej) => {
    chrome.devtools.inspectedWindow.eval(expr, {}, (result, except) => {
      if (except.isException || except.isError) {
        return rej(except)
      }
      res(result)
    })
  })
}

function createPanel(name: string, path: string): Promise<ExtensionPanel> {
  return new Promise((res, rej) => {
    chrome.devtools.panels.create("Hypermerge", "", "index.html", panel => {
      if (panel) return res(panel)
      rej()
    })
  })
}
