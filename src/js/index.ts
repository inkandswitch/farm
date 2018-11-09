process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = "1"

import App from "./App"
import Debug from "debug"

Debug.enable("*")

const app = new App()

app.start()
