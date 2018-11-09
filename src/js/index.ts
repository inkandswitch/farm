process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

import App from "./App"
import Debug from "debug"
;(self as any).Debug = Debug

const app = new App()

app.start()
