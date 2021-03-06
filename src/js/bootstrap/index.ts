import { readFileSync } from "fs"
import path from "path"
import Repo from "../Repo"
import mime from "mime-types"
import * as Diff from "../Diff"

export interface Opts {
  [k: string]: any
}

export const cache = new Map<string, string>()

export function code(identity: string, repo: Repo, file: string, opts: Opts = {}): string {
  const cached = cache.get(file)
  if (cached) {
    repo.change(cached, (state: any) => {
      const changes = Diff.getChanges(state, opts).filter(
        ch => !["rm", "unset"].includes(ch.type),
      )
      Diff.applyChanges(state, changes)
    })
    return cached
  } else {
    const created = createCode(identity, repo, file, opts)
    cache.set(file, created)
    return created
  }
}

export function createCode(identity: string, repo: Repo, file: string, opts: Opts = {}): string {
  const name = file.replace(/\.elm$/, "")
  opts.title = opts.title || `${name} source`
  opts.lastEditTimestamp = Date.now()
  if (identity) {
    opts.authors = [identity]
  }
  return repo.create({ ...opts, "Source.elm": sourceFor(file) })
}

export function sourceFor(name: string) {
  return readFileSync(path.resolve(`src/elm/examples/${name}`)).toString()
}

export function asset(repo: Repo, filename: string) {
  const mimeType = mime.lookup(filename) || "application/octet-stream"
  const data = readFileSync(path.resolve(`assets/${filename}`))
  return repo.writeFile(data, mimeType)
}
