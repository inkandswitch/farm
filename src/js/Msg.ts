export type Compile = ["Compile", string]
export type Compiled = ["Compiled", string]
export type CompileError = ["CompileError", string]

export interface Doc {
  t: "Doc"
  doc: object
}

export type ToServer = Compile
export type FromServer = Compiled | CompileError

export type ToRepo = Doc
export type FromRepo = Doc
