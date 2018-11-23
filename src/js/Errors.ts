export type CompileErrors = CompileError[]

export interface CompileError {
  name: string
  path: string
  problems: Problem[]
}

export interface Problem {
  title: string
  region: Region
  message: (string | ProblemMsg)[]
}

export interface Region {
  start: LineColumn
  end: LineColumn
}

export interface LineColumn {
  line: number
  column: number
}

export interface ProblemMsg {
  bold?: boolean
  underline?: boolean
  color: string
  string: string
}

export function log(err: CompileError): void {
  console.error(...toLogStrings(err))
}

export function toLogStrings(err: CompileError): string[] {
  let text = ""
  const formats: string[] = []

  err.problems.forEach(prob => {
    prob.message.forEach(msg => {
      if (typeof msg === "string") {
        text += msg
        // formats.push("background: #eee;display:inline;")
      } else {
        // const [txt, fmt] = format(msg)
        text += msg.string
        // formats.push(fmt)
      }
    })
  })

  return [text, ...formats]
}

// NOTE: this doesn't work
function format(msg: ProblemMsg): [string, string] {
  return [
    "%c" + msg.string,
    `display: inline;` +
      `background: #aaa;` +
      `font-weight:${msg.bold ? "bold" : "normal"};` +
      `text-decoration:${msg.underline ? "underline" : "none"};` +
      `color:${msg.color === "yellow" ? "orange" : msg.color};`,
  ]
}
