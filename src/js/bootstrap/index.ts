import { readFileSync } from "fs"
import path from "path"
import Repo from "../Repo"
import mime from "mime-types"

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

export function assetDataUrl(repo: Repo, filename: string) {
  const mimeType = mime.lookup(filename) || "application/octet-stream"
  const data = readFileSync(path.resolve(`assets/${filename}`))
  return repo.writeFile(data, mimeType)
}
