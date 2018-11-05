# Realm

Runtime-editable elm inside electron.

## Setup

```bash
yarn
yarn start
```

## TODO

- bot api
  - elm custom element wrapping bot
  - bot compilation bot
  - elm compilation bot
  - TS compilation bot
- render elm widgets as custom elements

## Idea history

- Connecting different modules
  - `import Foo` with a mapping of `source docId -> Module`?
    - Maybe a custom package manager?
  - Custom syntax `import Foo from "abc123"`?
  - No importing; use Json.Value messages with a `postMessage` router?
    - Simplest implementation. More annoying as a user.
- compile elm on client
  - compile elm/compiler to js (prior art exists for elm 0.18)?
  - run in electron and ship elm/compiler?
- automerge in elm
  - rewrite automerge/frontend in pure elm?
    - send requests and receive patches through ports
  - fork elm compiler and use Kernel code with existing automerge?
    - compiler not compile Kernel code from outside github.com/elm
