export function whenChanged<T, V>(
  get: (t: T) => V | undefined,
  fn: (v: V, t: T) => void,
) {
  let v: V | undefined

  return (t: T) => {
    const newV = get(t)
    if (newV === undefined) return
    if (v === newV) return
    v = newV
    fn(v, t)
  }
}
