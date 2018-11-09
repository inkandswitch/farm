export type Compile = ["Compile", string]
export type Compiled = ["Compiled", string]
export type CompileError = ["CompileError", string]

export type ToServer = Compile
export type FromServer = Compiled | CompileError
