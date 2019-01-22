const encoder = new TextEncoder()

export async function sha1(input: string) {
  return digest("SHA-1", input)
}

export async function digest(algo: string, input: string): Promise<string> {
  const buffer = encoder.encode(input)
  const result = await crypto.subtle.digest(algo, buffer)
  return toHex(result)
}

export function toHex(buffer: ArrayBuffer) {
  return [...new Uint8Array(buffer)]
    .map(b => b.toString(16).padStart(2, "0"))
    .join("")
}
