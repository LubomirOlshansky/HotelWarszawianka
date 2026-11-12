# Change notes: one small file per pull request

A pull request does **not** edit `docs/CHANGELOG.md`, `docs/BACKLOG.md` or `docs/ROADMAP.md`.
It adds one file here instead. Two pull requests never touch the same file, so they never
conflict on the docs (before 2026-11-12 those three were the most edited files in the repo, and
branches merged main into themselves about twice per pull request because of them).

## The file

Name: `YYYY-MM-DD-short-name.md` (today's date, lower case, hyphens), for example
`2026-11-12-ride-stories.md`.

```markdown
- Eight new Podwózka passengers with their own stories and places to go.

## Backlog
- fixed: PT-52, the map's Quit left the night meet running
- found: the kiosk on Tamka has no night light

## Roadmap
- ticked: "Side jobs: Podwózka stories"
```

- **The lines at the top** are for the player: plain words, no file names, no spoilers. They show
  on https://aroundwarsaw.app/progress/ and in the wiki as soon as the pull request lands. A change
  nobody can see (tooling, CI, a refactor) has no top line.
- **Backlog** (optional): what this change fixed (to remove) and what it found (to add).
- **Roadmap** (optional): the v1.0 checklist line this change ticks or adds.

`python3 -I tools/changelog.py --check` checks the format (CI runs it on every pull request).

## The weekly fold

Once a week one bookkeeping pull request runs `python3 -I tools/changelog.py --fold`: the top
lines move into `docs/CHANGELOG.md` under their day, the Backlog and Roadmap lines are printed
and applied to those files by hand, and the notes are deleted. Nobody else edits the three big
files, except to park or answer a question in `docs/QUESTIONS.md`.
