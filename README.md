# Realm

## Setup

```bash
yarn
yarn start
open http://localhost:4000
```

## TODO

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
