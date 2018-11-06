export type CompileError = ["CompileError", string]
export type Compile = ["Compile", string]
export type Compiled = ["Compile", string]

export interface SaveDoc {
  t: "SaveDoc"
  docId: string
  doc: object
}

export interface Doc {
  t: "Doc"
  docId: string
  doc: object
}

export type ToServer = Compile
export type FromServer = Compiled | CompileError

export type ToRepo = SaveDoc
export type FromRepo = Doc
