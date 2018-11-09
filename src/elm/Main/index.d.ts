// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/dillonkearns/elm-typescript-interop
// Type definitions for Elm ports

export namespace Elm {
  namespace Main {
    export interface App {
      ports: {
        fromServer: {
          send(data: [string, string]): void
        }
        fromRepo: {
          send(data: any): void
        }
        toServer: {
          subscribe(callback: (data: [string, string]) => void): void
        }
        toRepo: {
          subscribe(callback: (data: unknown) => void): void
        }
      }
    }
    export function init(options: {
      node?: HTMLElement | null
      flags: string
    }): Elm.Main.App
  }
}
