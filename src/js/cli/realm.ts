#!/usr/bin/env ts-node

;(<any>global).Worker = require("tiny-worker")

import program from "commander"

import Repo from "../Repo"
import Compiler from "../Compiler"
import Bot from "../Bot"
import fs from "fs"

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
  .description("run a realm bot")
  .action((codeUrl, dataUrl) => {
    const compiler = new Compiler(repo, "dist/compile.worker.js")

    Bot.repo = repo
    Bot.compiler = compiler

    const bot = new Bot(codeUrl, dataUrl)
    bot.start()
  })

program
  .command("create <elmFile>")
  .description("create a realm bot from an elm file")
  .action(filename => {
    const source = fs.readFileSync("./src/elm/examples/" + filename).toString()
    const url = repo.create({
      title: filename + " source",
      "Source.elm": source,
    })

    console.log("\n\nbot code url:", url, "\n\n")
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
