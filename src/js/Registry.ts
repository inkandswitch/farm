import { RepoFrontend } from "hypermerge"
import Widget from "./Widget"
import Handle from "hypermerge/dist/handle"

export default class Registry {
  repo: RepoFrontend
  entries = new Map<string, Entry>()

  constructor(repo: RepoFrontend) {
    this.repo = repo
  }

  add(name: string, id: string): void {
    this.entries.set(id, new Entry(name, this.repo.open(id)))
  }
}

export class Entry {
  handle: Handle<any>
  name: string

  constructor(name: string, handle: Handle<any>) {
    this.handle = handle
    this.name = name
  }
}
