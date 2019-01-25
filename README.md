# Farm

Farm is an experiment in distributed peer-to-peer computing. Farm is an extensible, programmable environment with real-time and offline collaboration with other users and no mandatory infrastructure. You can program Farm using the Elm programming language, and changes you make to the code will be shared in real-time with users anywhere in the world.

Farm also includes a demonstration application inspired by tools like Google Keep, Milanote, or Trello.

It partners particularly well with our [vscode plugin](https://github.com/inkandswitch/vscode-hypermerge/).

## Caveat Emptor

Warning! Farm is experimental software. It makes no guarantees about performance, security, or stability. Farm will probably consume all the memory on your computer, leak your data to your worst enemy, and then delete it.

That said, if you encounter Farm bugs or defects, please let us know. We're interested in hearing from people who try the software.

## Trying Farm

Clone this repo, then start the application.

```bash
yarn
yarn start
```

You should see a "welcome" board with a navigation URL. This is the Farm demonstration application. Everything you see is self-hosted in Farm and can be edited by you, from the navigation bar at the top to the typeface used on the welcome card.

## Using FarmPin

FarmPin is a tool for collecting and sharing ideas. You can use it to plan a trip or a project, create a mood board, or to improvise an ad-hoc user interface for an application you're working on.

- You can right-click to create new notes on your board or resize and drag notes around by clicking on the bar at the top.
- You can make the current card full-screen by double clicking on the top 20px of the card navigate back (or forward) to the previous view with the arrow buttons left of the title bar.
- Delete a card by right-clicking on the top 20px and clicking "Remove".
- Share a link to your current view (and it's code!) by copying the URL out of the title bar and pasting it to another user. Be careful -- anyone with the link to a Farm document can not only view it now but all future versions as well and their modifications to the code or data will be merged with your own.

## Working on Farm Applications

Farm applications are built out of Gizmos. A Gizmo is the combination of some data with a small Elm program to render it as a Web Component. Changes to the Elm code for a Gizmo are compiled automatically into Javascript by the Farm runtime, and changes to the data document will trigger a re-rendering of the content as well.

All documents in Farm, both data and code, are Hypermerge documents. A Hypermerge document is identified by its URL, and anyone with the URL is able to make changes to it and should expect them to be synchronized everwhere in the world. All hypermerge documents are constructed out of their full history.

The best supported way of working on a Farm application is through the Hypermerge VSCode extension. To import your data and code into the VSCode extension, paste it into the "Open Document" dialogue for the extension. Further details on this process are describe in the README for that project.

A farm:// URL has two parts -- the first half tells Farm which code to run, and the second half describes the data document to render with that code. You can pair any code with any document and Farm will do its best to make it work.

When editing Farm code in VSCode changes made to a Source.elm key will be synchronized to Farm which will attempt to compile them with the Elm compiler. If the compile is successful, the result will be written to Source.js. If the compile fails, the errors will be written to a hypermergeFsDiagnostics key which VSCode will render as code error highlighting within the relevant buffer.

Good luck! If you have questions, don't hesitate to ask here in the Github Issues or on the automerge slack.

### Code highlighting & formatting for Elm code in Hypermerge

The upstream Elm extension assumes files are written to disk, which Hypermerge documents are not. As a result, when working on Hypermerge documents you'll want to use our patched version of the Elm vscode extension. Download the [latest Release](https://github.com/inkandswitch/vscode-elm/releases/latest). Install by selecting
"Extensions: Install from VSX..." from the Command Palette, and selecting the downloaded
.vsx file.
