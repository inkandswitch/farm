export interface Compile {
  t: "Compile"
  url: string
  source: string
  sourceHash: string
  config: { [k: string]: string }
  debug?: boolean
}

export interface Compiled {
  t: "Compiled"
  url: string
  sourceHash: string
  outputHash: string
  output: string
}

export interface CompileError {
  t: "CompileError"
  url: string
  sourceHash: string
  error: string
}

export type ToCompiler = Compile
export type FromCompiler = Compiled | CompileError
