process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

import App from "./App"
import Debug from "debug"

Object.assign(self, {
  Debug,
  app: new App(),
})
