# Issue tracker: GitHub Issues

Tickets for this repo live in GitHub Issues at `waleed-khalaf/BampireSurbibors`, and that's the only copy. Use the `gh` CLI for all of it. Specs are documents, not tickets: they live in `docs/` (for example `docs/demo-spec.md`) and change through PRs like the code.

## Conventions

- **Title:** `NN: <ticket name>`. NN is the ticket number, counted from `01` and continuing the existing sequence. It is not the GitHub issue number: ticket 27 is issue #28, because #27 is a PR. Refer to tickets in prose as "ticket NN" and link them as `#N`.
- **Body:**

  ```
  **What to build:** <one paragraph>

  **Blocked by:** #N (<ticket name>), #N (<ticket name>)   (or "None (can start immediately)")

  - [ ] <acceptance criterion>
  - [ ] ...

  ---
  Spec: `docs/<spec>.md`
  ```

- **Triage state:** exactly one triage label per issue (see `triage-labels.md`). There is no `Status:` line in the body.
- **Progress:** tick a criterion's box in the issue body (`gh issue edit N --body-file -`) when it's done.
- **Comments and history:** issue comments (`gh issue comment N`). Start one with the date and author, for example `**2026-11-06 (Claude):** Implemented...`.
- **Closing:** a PR that finishes a ticket says `Closes #N` in its description, one line per ticket, so GitHub closes the issue when the PR merges.

## When a skill says "publish to the issue tracker"

For a ticket, create the issue with the title, body and triage label above:

```
gh issue create --title "NN: <ticket name>" --body-file <file> --label ready-for-agent
```

For a spec, write it under `docs/` and commit it; don't make it an issue.

## When a skill says "fetch the relevant ticket"

The user will normally give the issue number, the ticket number or the title. Read it with:

```
gh issue view N --comments
```

To find a ticket by its ticket number, search the titles: `gh issue list --state all --search "NN: in:title"`. If the reference is ambiguous, ask.

## Wayfinding operations

Used by `/wayfinder`. The **map** is one issue, and each **child** is its own issue.

- **Map:** an issue titled `Map: <effort>` with the `wayfinder-map` label. Its body holds the Notes, Decisions-so-far and Fog sections.
- **Child ticket:** an issue whose body starts with `Part of #<map>` and a `**Type:**` line (`research`/`prototype`/`grilling`/`task`), followed by the question.
- **Blocking:** a `**Blocked by:** #N, #N` line near the top. A child is unblocked when every issue it lists is closed.
- **Frontier:** open children of the map (`gh issue list --state open --search "\"Part of #<map>\" in:body"`) that are unblocked and don't have the `claimed` label. The lowest issue number wins.
- **Claim:** add the `claimed` label before any work (`gh issue edit N --add-label claimed`).
- **Resolve:** post the answer as a comment starting with `## Answer`, close the issue, then add a context pointer (the gist plus a link to the issue) to the map's Decisions-so-far.

Create the `wayfinder-map` and `claimed` labels with `gh label create` the first time they're needed.
