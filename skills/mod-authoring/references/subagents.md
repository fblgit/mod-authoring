# Subagents and swarm panes

Sources: mods `reference.md` (Subagents, `$.agent`, `tool.check` fields), `events.md` (Follow a turn), `api.md` (messaging, interrupts), local `claude-code.d.ts` (`AgentInfo` line 125, `AgentSpawnInput` line 261, `SubagentStartHookInput` line 13054). Grep the types for the full field lists; only the fields below were read.

## Events and calls

| Item | Facts |
| :- | :- |
| `agent.offer` | fires when a type is offered to the model; `{isOffered:false}` withholds it; matcher `{agent:'<type>'}`; the mod's own spawn still works |
| `agent.spawn` | fires when a subagent or teammate is about to start; `e.isTeammate`; input includes `tool_use_id`, `prompt`, `description`, resolved agent type; return `next({...e, model})` or `{deny}`; a rewritten `prompt` is what runs |
| `agent.spawn` not refired | when the SendMessage tool resumes a subagent; match SendMessage in a `tool.call` hook to see it |
| `$.agent.list()` | subagents and teammates; status `pending running waiting idle completed failed killed` (`idle`, `waiting` need 2.1.289) |
| `$.agent.spawn({subagentType})` | resolves its `turn.complete`; resolves `{deny}` after a user interrupt |
| `$.agent.register(spec)` | type named `<plugin>:<name>`; call in `session.start` (an old copy after reload is refused) |
| `AgentInfo.id` | the one id: equals `agentId` on loop events and `agent_id` on classic events; teammates also have `teammateId` (`name@team`) |

## Attributing activity to one agent

| Event | Field |
| :- | :- |
| `tool.call` | covers subagent and MCP calls (agent attribution not read) |
| `tool.check` | `e.agentId` absent for the main conversation (2.1.290) |
| `turn.step` | `e.agentId` set for a subagent request; `result.usage` has input, output, cache_read, cache_creation tokens and `model` |
| `turn.complete` | `e.agentId`, `isAborted`, `durationMs`, `answer`, `usage` |
| `classic.SubagentStart` | `agent_id`, `agent_type` |
| `classic.SubagentStop` | `agent_id`, `agent_type`, `agent_transcript_path`, `last_assistant_message?` |

## Messaging

`$.session.send({ to: { agentId }, text })` with ids from `$.agent.list()`. Resolves `{isDelivered, reason?}`. A finished subagent is resumed unless the session was interrupted. Observe traffic with `session.send` and `session.receive` (`e.origin.kind`: `peer`, `peer-send-message`, `task-notification`, `scheduled-trigger`, `model`, `plugin`).

## Pane recipe

1. `session.start`: register the command, start `$.clock.every(1000, …)` that updates an atom and invalidates only while something runs.
2. Keep a worker list in `$.state` (atom) so a reload keeps it; reload from `$.store` on `classic.SessionStart` if it must survive `/clear`.
3. `ui.render {component:'Pane', requestId}`: size to `bodyColumns`; one Button per worker row (strings and Text children), key `'w-'+id`.
4. Stop buttons: confirm with a two-tap armed state in `$.state`, then call the stop tool.
5. Open with a command; for auto-open on `agent.spawn` check `isPlaced` and fall back to a toast.

Not in the docs: swarm protocol (glyphs, shards, peers). That lives in `skills/context-federation/SKILL.md`.
