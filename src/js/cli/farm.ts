;(<any>global).Worker = require("tiny-worker")

import program from "commander"

import Repo from "../Repo"
import Compiler from "../Compiler"
import Bot from "../Bot"
import * as Bs from "../bootstrap"
import * as FarmUrl from "../FarmUrl"

program.version("0.1.0")

const repo = new Repo("dist/repo.worker.js")

program
  .command("help")
  .description("displays this usage information")
  .action(() => {
    program.help()
  })

program
  .command("bot <codeUrl> <dataUrl>")
  .description("run a farm bot")
  .action((codeUrl, dataUrl) => {
    const compiler = new Compiler(repo, "dist/compile.worker.js")

    Bot.repo = repo
    Bot.compiler = compiler

    const bot = new Bot(codeUrl, dataUrl)
    bot.start()
  })

program
  .command("bootstrap <gizmo-name>")
  .description("Bootstrap a gizmo from src/js/bootstrap.")
  .action((gizmo: string) => {
    const bs = require("../bootstrap/" + gizmo)
    const code = bs.code("", repo)
    const data = bs.data("", repo)
    const farmUrl = FarmUrl.create({ code, data })
    console.log(`Successfully bootstrapped ${gizmo}!\n\nurl:`, farmUrl)
    repo.terminate()
    //setTimeout(() => {}, 99999999) // HACK: without a worker, node exits
  })

program
  .command("create <elmFile>")
  .description("Create a farm gizmo from an elm file")
  .action(filename => {
    const url = Bs.code("", repo, filename)
    console.log("\n\ngizmo code url:", url, "\n\n")
    setTimeout(() => {}, 99999999) // HACK: without a worker, node exits
  })

program.on("command:*", () => {
  console.error("Invalid command: %s\n", program.args.join(" "))
  program.help()
})

// Start the cli:
program.parse(process.argv)

if (!process.argv.slice(2).length) {
  program.help()
}
