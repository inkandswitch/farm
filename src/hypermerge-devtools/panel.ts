chrome.devtools.inspectedWindow.eval(
  "console.log('testing')",
  (result, except) => {
    if (except.isException) {
      console.log("exception")
    }
  },
)
