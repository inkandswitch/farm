const encoder = new TextEncoder()
const decoder = new TextDecoder()

export async function sha1(input: string) {
  return digest("SHA-1", input)
}

export async function digest(algo: string, input: string): Promise<string> {
  const buffer = encoder.encode(input)
  const result = await crypto.subtle.digest(algo, buffer)
  return decoder.decode(result)
}
