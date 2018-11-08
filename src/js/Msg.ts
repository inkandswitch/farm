export type Compile = ["Compile", string]
export type Compiled = ["Compiled", string]
export type CompileError = ["CompileError", string]

export interface Doc {
  t: "Doc"
  docId: string
  doc: object
}

export interface Open {
  t: "Open"
  docId: string
}

export interface Create {
  t: "Create"
  doc: object
}

export interface Ready {
  t: "Ready"
  rootUrl: string
}

export interface Start {
  t: "Start"
  rootUrl?: string
}

export type ToServer = Compile
export type FromServer = Compiled | CompileError

export type ToRepo = Doc | Create | Start | Open
export type FromRepo = Doc | Ready
