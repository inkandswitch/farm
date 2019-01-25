export interface Pair {
  code: string
  data: string
}

export function create({ code, data }: Pair) {
  const codeId = new URL(code).pathname.slice(1)
  const dataId = new URL(data).pathname.slice(1)
  return `farm://${codeId}/${dataId}`
}
