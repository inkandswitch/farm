import { readFileSync } from "fs"
import path from "path"
import Repo from "../Repo"

export interface Opts {
  [k: string]: any
}

export function code(repo: Repo, file: string, opts: Opts = {}): string {
  opts.title = opts.title || `${file} source`
  return repo.create({ ...opts, "Source.elm": sourceFor(file) })
}

export function sourceFor(name: string) {
  return readFileSync(path.resolve(`src/elm/examples/${name}`)).toString()
}

export function assetDataUrl(filename: string) {
  const base64 = readFileSync(path.resolve(`assets/${filename}`), "base64")
  return `data:image/png;base64,${base64}`
}
