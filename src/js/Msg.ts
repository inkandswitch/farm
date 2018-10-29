export type CompileError = ["CompileError", string]
export type Compile = ["Compile", string]
export type Compiled = ["Compile", string]

export type ToServer = Compile
export type FromServer = Compiled | CompileError
