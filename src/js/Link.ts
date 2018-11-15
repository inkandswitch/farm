import * as Base58 from "bs58"

export const SCHEME = "hypermerge"

export type Link = string

export interface Params {
  readonly height?: number
  readonly width?: number
}

export interface Spec {
  readonly url: string
  readonly id: string
  readonly scheme: string
  readonly params: Params
}

export interface LinkArgs extends Pick<Spec, "id"> {
  readonly params?: Params
}

export const create = ({ id, params }: LinkArgs): string => {
  return `${SCHEME}://${id}/${params ? createParams(params) : ""}`
}

export function fromId(id: string): string {
  return create({ id })
}

export function toId(link: string): string {
  return parse(link).id
}

export const createParams = (params: Params): string => {
  const keys = Object.keys(params) as Array<keyof Params>
  if (keys.length === 0) return ""

  return "?" + keys.map(k => `${k}=${params[k]}`).join("&")
}

export const parse = (url: string): Spec => {
  const { scheme, id, params = {} } = parts(url)

  if (!id) throw new Error(`Url missing id in ${url}.`)

  if (scheme !== SCHEME) {
    throw new Error(`Invalid url scheme: ${scheme} (expected ${SCHEME})`)
  }

  return { url, scheme, id, params }
}

export const set = (url: string, opts: Partial<LinkArgs>) => {
  const { id, params } = parse(url)
  return create({ id, params, ...opts })
}

export const setType = (url: string) => {
  const { id } = parse(url)
  return create({ id })
}

export const parts = (url: string): Partial<Spec> => {
  const [, /* url */ scheme, id, query = ""]: Array<string | undefined> =
    url.match(/^(\w+):\/\/(\w+)\/(?:\?([&.\w=-]*))?$/) || []
  const params = parseParams(query)
  return { scheme, id, params }
}

export const parseParams = (query: string): Params => {
  return query
    .split("&")
    .map(q => q.split("="))
    .reduce(
      (params, [k, v]) => {
        params[k] = parseParam(k, v)
        return params
      },
      {} as any,
    )
}

export function parseParam(k: "height", v: string): number
export function parseParam(k: "width", v: string): number
export function parseParam(k: string, v: string): string
export function parseParam(k: string, v: string): string | number {
  switch (k) {
    case "height":
    case "width":
      return parseFloat(v)

    default:
      return v
  }
}

export const isValidLink = (val: string): boolean => {
  try {
    parse(val)
  } catch {
    return false
  }
  return true
}

export const hexTo58 = (str: string): string =>
  Base58.encode(Buffer.from(str, "hex"))
