import { RepoFrontend } from "hypermerge/dist/RepoFrontend"

export function worker(url: string): RepoFrontend {
  const worker = new Worker(url)
  const repo = new RepoFrontend()

  worker.onmessage = event => {
    repo.receive(event.data)
  }

  repo.subscribe(msg => {
    worker.postMessage(msg)
  })

  return repo
}
