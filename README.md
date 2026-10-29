# mod-authoring

A Claude Code plugin with one skill, `mod-authoring`: rules, references and example mods for building, testing, securing and auditing Claude Code mods.

## Install

```
/plugin install mod-authoring@fblgit-claude-marketplace
```

From a shell:

```
claude plugin install mod-authoring@fblgit-claude-marketplace
```

## What is inside

| Path | Content |
| :- | :- |
| skills/mod-authoring/SKILL.md | index and 14 rules |
| skills/mod-authoring/references/ | 13 reference files |
| skills/mod-authoring/examples/ | 7 loadable example mods |
| scripts/check.sh | validate, test and type-check every example (no model call) |

Keeping it current: run scripts/check.sh after each Claude Code update.

Tested against Claude Code 2.1.309. The types Claude Code writes beside a mod win over these notes.

## License

MIT
