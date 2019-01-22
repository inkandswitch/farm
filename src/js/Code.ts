import Repo from "./Repo"

export async function source(repo: Repo, doc: any): Promise<string> {
  if (doc.outputUrl) {
    const { text } = await repo.readFile(doc.outputUrl)
    return text
  } else if (doc["Source.js"]) {
    return doc["Source.js"]
  } else {
    throw new Error("No source available")
  }
}
