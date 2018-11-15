export interface Compile {
  t: "Compile"
  url: string
  source: string
}

export interface Compiled {
  t: "Compiled"
  url: string
  output: string
}

export interface CompileError {
  t: "CompileError"
  url: string
  error: string
}

export type ToCompiler = Compile
export type FromCompiler = Compiled | CompileError
