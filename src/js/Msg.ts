export interface Compile {
  t: "Compile"
  id: string
  source: string
}

export interface Compiled {
  t: "Compiled"
  id: string
  output: string
}

export interface CompileError {
  t: "CompileError"
  id: string
  error: string
}

export type ToCompiler = Compile
export type FromCompiler = Compiled | CompileError
