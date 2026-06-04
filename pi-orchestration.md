# pi-orchestration

> A pi extension for running an **agent team**: one orchestrator parent, many
> specialized subagents, structured decision routing, bounded probes, and a
> sidecar status panel — designed so the parent's context window stays clean
> while children do the messy I/O.

Status: spec / pitch
Author: bragur
Target package name: `pi-orchestration`
Related prior art: `pi-subagents`, `pi-intercom`
Relationship: **standalone replacement**, not a layer on top.

---

## 1. Why this exists

Today, delegating work to subagents in pi works functionally (verified via
smoke test in this session), but the **control plane and the conversation
plane are the same plane**:

- Subagent "needs decision" messages are posted into the visible transcript.
- Async completion notices, late-delivered asks, intercom routing details,
  and child session IDs all land in the user's chat window.
- Child outputs default to inline; the parent context absorbs raw research,
  raw grep results, raw logs.
- Multi-agent status is invisible unless you grep async run directories.

For one-off delegation, that is fine. For a real **agent team** — parent
orchestrator spawning explorers, scouts, researchers, implementers, and
reviewers — it is not. The parent's context window fills up with control
chatter, and the user can't see what their team is doing without polluting
the orchestration thread.

`pi-orchestration` separates the planes:

1. **Conversation plane** — parent ↔ human only.
2. **Control plane** — parent ↔ children, typed events, sidecar storage.
3. **Artifact plane** — large outputs, logs, traces, references only.

The parent remains the single conversational authority. Children are
autonomous workers with structured escalation paths and bounded outsourcing
helpers. Status is rendered in a TUI sidecar panel, not the transcript.

---

## 2. Goals

- **Context-protect the parent.** Children never inject raw I/O into the
  parent's prompt; only typed summaries and references.
- **Typed escalation.** Children can ask the parent specific, structured
  questions and block until answered, without dumping prose into chat.
- **Per-child model + budget assignment.** The orchestrator/runtime assigns
  each subagent's model, context budget, tool set, and write permissions from
  role defaults, parent policy, and explicit spawn overrides. Subagents may
  request changes, but the broker enforces all limits.
- **Live, out-of-band status.** A TUI sidecar shows every agent: role,
  model, state, context %, last activity.
- **Bounded outsourcing.** Children can call **probes** (deterministic) and
  **mini-LLM probes** (constrained) to compress messy I/O, but cannot
  spawn full agents themselves.
- **Recover across pi restarts.** Run state, decisions, and artifacts are
  persisted; on startup pi reconstructs the last known state, marks any
  in-flight child work as interrupted, and surfaces unresolved decisions.
- **Verifiable.** Every requirement in §18 has an observable assertion.

## 3. Non-goals

- **No recursive orchestration.** Subagents may not spawn subagents. They
  may only call probes/reducers with bounded budgets.
- **No free-form child↔child chat.** Inter-child coordination is mediated
  by the parent or by shared artifacts.
- **No multi-machine orchestration in MVP.** Same-host process tree only.
- **No replacement for pi's session/model layer.** We use pi's existing
  model registry, session persistence, and tool runtime.
- **No "agent personality" customization.** Roles are functional contracts,
  not characters.
- **No replacement of `pi-subagents` for casual one-shot delegation.** That
  package keeps working; `pi-orchestration` is a separate, more opinionated
  package for team-shaped workflows.

---

## 4. Concepts and vocabulary

| Term | Definition |
|------|-----------|
| **Orchestrator** | The parent pi session. Sole conversational authority with the human. |
| **Subagent / Agent** | A role-bound child process running an LLM with an assigned model, tool set, and budget. Long-lived relative to a single mission. |
| **Role** | A reusable contract (e.g. `scout`, `researcher`, `reviewer`, `worker`). Defines default model, tools, prompt, output schema, and permissions. |
| **Orchestrator Playbook** | A markdown workflow contract for the parent orchestrator itself: which roles/skills to use, what loop to follow, and what minimum output schema to request from each child. |
| **Mission** | The concrete task assigned to one subagent instance. |
| **Probe** | A bounded helper a subagent can invoke to outsource I/O. Two classes: *deterministic probes* (no LLM) and *LLM probes* (short-lived constrained LLM calls). |
| **Reducer** | A specific probe whose job is compression/summarization of large inputs into a fixed schema. |
| **Artifact** | Any persisted file produced by an agent/probe (raw logs, full research, diffs, evidence). Lives on disk; referenced by ID. |
| **Decision Request** | A typed, blocking question from a child to the parent. |
| **Status Sidecar** | The TUI panel that renders live agent state without affecting the transcript. |
| **Run** | A single orchestration session: one parent, N agents, M artifacts, K decisions. |

---

## 5. Architectural overview

```
                 ┌──────────────────────────────┐
                 │       Human user (TUI)       │
                 └─────────────┬────────────────┘
                               │  conversation plane
                 ┌─────────────▼────────────────┐
                 │     Orchestrator (parent)     │
                 │  - sole user-facing agent     │
                 │  - decides, asks, summarizes  │
                 └──┬──────┬──────┬──────┬───────┘
                    │      │      │      │   control plane (typed events)
            ┌───────▼┐ ┌───▼──┐ ┌─▼────┐ ┌▼────────┐
            │ scout  │ │ rev. │ │ res. │ │ worker  │   subagents
            └───┬────┘ └──┬───┘ └──┬───┘ └──┬──────┘
                │         │        │        │      probe plane
            ┌───▼──┐  ┌───▼──┐ ┌───▼──┐ ┌───▼──┐
            │probe │  │probe │ │probe │ │probe │
            └──────┘  └──────┘ └──────┘ └──────┘

      ┌───────────────────────────────────────────────┐
      │   Artifact store (filesystem-backed, on disk)  │
      └───────────────────────────────────────────────┘

      ┌───────────────────────────────────────────────┐
      │   Run state + decision queue (JSONL + index)   │
      └───────────────────────────────────────────────┘

      ┌───────────────────────────────────────────────┐
      │   TUI sidecar panel (renders status only)      │
      └───────────────────────────────────────────────┘
```

Three rules govern every interaction:

1. **Parent owns conversation.** Only the orchestrator may message the human.
   Children may not.
2. **Children escalate by typed event, not prose.** All child→parent
   communication is a structured event with a kind, schema, and ID.
3. **Bulk data lives on disk.** Large outputs go to the artifact store;
   only references and compact summaries enter parent context.

---

## 6. Three planes, in detail

### 6.1 Conversation plane

- Only the parent emits visible messages.
- Status changes (`scout-1 started`, `reviewer-2 complete`) do **not**
  auto-post. They update the sidecar.
- The parent may *choose* to summarize team activity to the user, but
  this is an explicit action ("brief me on the team"), not a side effect.
- Decision requests from children are surfaced to the user *only when the
  parent's policy says so* (e.g. parent cannot auto-answer, no cached
  policy, escalation required).

### 6.2 Control plane

All child↔parent traffic is typed events on a per-run broker (IPC: unix
domain socket + length-framed JSON, same pattern as `pi-intercom`'s
`broker/framing.ts`). Events are append-only to `events.jsonl` in the run
directory.

Event kinds (initial set):

| Kind | Direction | Blocking | Purpose |
|------|-----------|----------|---------|
| `agent.spawned` | child→parent | no | Agent process started. |
| `agent.state` | child→parent | no | Lifecycle transition. |
| `agent.heartbeat` | child→parent | no | Liveness + ctx usage snapshot. |
| `agent.progress` | child→parent | no | Short progress note (≤ 200 chars). |
| `agent.complete` | child→parent | no | Mission done, summary + artifact refs. |
| `agent.failed` | child→parent | no | Mission failed, error + artifacts. |
| `decision.request` | child→parent | yes | Typed question; child blocks. |
| `decision.reply` | parent→child | n/a | Resolves a `decision.request`. |
| `instruction` | parent→child | no | Free-form-ish narrowing/redirect. |
| `control.pause` | parent→child | no | Pause child turn. |
| `control.resume` | parent→child | no | Resume paused child. |
| `control.terminate` | parent→child | no | Hard stop child. |
| `probe.invoked` | child→logs | no | Audit record only. |
| `artifact.written` | child→parent | no | Path + size + kind. |

Every event has a stable shape:

```ts
type Event = {
  id: string;            // ULID
  runId: string;
  agentId?: string;      // omitted for parent-originated events
  kind: EventKind;
  ts: number;            // ms epoch
  payload: unknown;      // kind-specific, schema validated
  parentEventId?: string; // for replies / threading
};
```

### 6.3 Artifact plane

- Every artifact has a stable `artifactId` plus metadata and is stored at
  `<runDir>/artifacts/<agentId>/<name>`. The path is run/agent/name-addressed;
  content hashes may be added later for dedupe/integrity, but are not required
  for MVP.
- Agents return **references**, not bodies: `{ artifactId, kind, bytes, lines, summary }`.
- The parent never auto-reads artifacts. It may call `artifact.read` when
  it actually needs the content — and even then prefers `artifact.summarize`
  via a reducer probe.

---

## 7. Roles

A role is a manifest, not a personality. Format (Markdown frontmatter,
same convention as pi-subagents agents):

```markdown
---
role: reviewer
description: Review-only critic with no write access.
defaultModel: anthropic/claude-haiku-4
defaultContextBudget: 200000
defaultTools: [read, grep, find, ls, bash-read-only]
writeAccess: false
canCallProbes: true
canAskUser: false                # always false; only parent asks user
allowedDecisionKinds:
  - need_decision
  - need_clarification
  - scope_boundary_hit
outputSchema: reviewer-findings@1
skills:
  inherit: true                  # see §7.1
  tags: [review]                 # filter inherited skills by tag (§7.1)
---

System prompt text...
```

### 7.1 Skill inheritance for children

Children get the same skill-discovery substrate the parent has — automatically,
at spawn time, not via a discovery agent. The role manifest declares one of
three modes via `skills:`:

- `skills: { inherit: true, tags?: [...] }` — child sees the parent's project,
  user, and builtin skills, filtered by the listed tags. With no tags, the
  child sees the same set the parent does.
- `skills: [name1, name2, ...]` — explicit allowlist. Only the listed skills
  are injected.
- `skills: false` — none.

Skill frontmatter may declare `tags:` (e.g. `[implementation, testing]`,
`[review, security]`, `[language:typescript]`). The runtime resolves skills at
spawn time and injects them into the child's system prompt using the same
`<available_skills>` block format the parent receives. Children never run a
discovery step, never read a manifest of which skills apply, and never need
bespoke frontmatter conventions to become visible to other agents.

Playbook authors may override at spawn time via `team({ action: "spawn",
agent: { skills: ... } })`. The broker enforces the same precedence as every
other resource: role default → playbook override → parent override → spawn
argument, with the broker as the final authority.

Built-in roles for MVP:

- `scout` — fast recon, returns compressed map of an area.
- `researcher` — external web research; bounded fetch budget.
- `context-builder` — produces structured context handoff documents.
- `reviewer` — review-only; cannot edit. Returns `findings@1`.
- `worker` — single-writer implementer; isolated worktree.
- `planner` — produces a plan artifact and a meta-prompt.

Role precedence (highest wins): project (`.pi/orchestration/roles/`) >
user (`~/.pi/orchestration/roles/`) > builtin.

### 7.2 Orchestrator playbooks

Roles describe child workers. **Playbooks** describe the parent orchestrator's
workflow: which roles to use, which loop to follow, how to escalate, what
result contract each child must return, and how stages compose.

Playbooks are markdown files with frontmatter. They live under
`<repo>/.pi/orchestration/playbooks/` (project) or
`~/.pi/orchestration/playbooks/` (user), with builtin playbooks shipping in the
extension. Precedence: project > user > builtin.

A playbook is parent-side instructions only. It does not spawn anything by
itself — the parent reads it and drives the run. Playbooks are *not* agents,
are *not* children, and never run in their own process.

#### 7.2.1 Capabilities a playbook must be able to express

The spec is correct only if every capability below is expressible without
resorting to ad-hoc prose discipline in the orchestrator. Each is independently
testable.

- **Stage sequencing.** An ordered list of stages, each invoking a role with a
  task template.
- **Stage-skip on existing artifacts.** A stage declares the artifact(s) it
  produces; the parent skips the stage if all declared artifacts already exist
  and pass an optional validity check.
- **Bounded loops.** A stage may loop with `maxRounds:` and an exit predicate
  (`passWhen:`) expressed as a jq-style selector over the most recent child
  result (e.g. `.status == "ready" and .criticalCount == 0`).
- **Parallel fan-out.** A stage may spawn N children of the same role with
  per-child task variation, and define how their results are combined (any,
  all, threshold, custom reducer probe).
- **Structured result contracts.** Each stage declares the minimum schema a
  child must return. The parent consumes only that schema; full content stays
  in artifacts. See §7.2.3.
- **Per-stage escalation policy.** Each stage can override the parent's
  default policy for `decision.request` handling (auto-answer, parent-decides,
  ask-user) per `kind`.
- **Stable artifact references.** Stages name their outputs (`spec`, `plan`,
  `review`, `qa`) so later stages and other playbooks can refer to them by
  name, not by path.
- **Composition.** A playbook may delegate a stage to another playbook. See
  §7.2.2.
- **Conditional stages.** A stage may be gated by a predicate over earlier
  stage results or existing artifacts (`when:` clause).
- **Entry and exit contracts.** A playbook declares the artifacts it expects to
  exist on entry (or empty) and the artifacts it guarantees on successful exit.
  These contracts make composition checkable.

#### 7.2.2 Composition

Playbooks compose by delegation: a stage may say "this stage is the playbook
`<name>`" instead of "this stage spawns role X". When the orchestrator reaches
that stage, it pushes the named playbook onto its playbook stack, runs it in
the same run with the same agents/artifacts available, and pops back to the
caller on completion.

Rules:

- Composition is **static** (parent reads playbooks and follows them). It is
  not a new spawning primitive. The "no recursive orchestration" non-goal in
  §3 is unaffected — there is still exactly one orchestrator process.
- The same run, run directory, and artifact namespace are shared. A composed
  playbook's outputs are visible to its caller by artifact name.
- A composed playbook's entry contract is checked against the caller's state
  before delegation; mismatches fail fast with an actionable error rather than
  silently producing garbage.
- A playbook may be invoked **standalone** as well as via composition. The
  parent's top-level entry is just "run playbook X".
- Cycles are rejected at load time.

This is what lets a delivery-pipeline-style meta-playbook compose narrower
sub-playbooks (spec-writing, planning, implementing, reviewing, finishing)
that are also useful on their own ("just review my diff", "just write the
spec"). Users mix and match — drop a stage, swap a sub-playbook for their own
variant, change a role's model — by editing markdown, not by reconfiguring
the runtime.

#### 7.2.3 Result contracts and minimum necessary context

The default orchestration rule is **minimum necessary context**: the parent
asks children for the smallest schema that can drive the next decision.
Schemas should be easy to reduce with `jq`-style selectors, so the parent
can consume a single field (`.status`, `.score`, `.criticalCount`) instead
of a whole report. If `status = ready` is enough, the child returns only
that. If a short summary is enough, the full artifact stays on disk.

Result contracts may come from the playbook stage, the invoked skill, the
child role, or a parent-generated schema, in that precedence order. If none
is specified, the parent must choose one before spawning the child rather
than accepting a prose dump.

#### 7.2.4 Worked sketch

A stage in a playbook looks roughly like this (illustrative, not normative
syntax):

```yaml
stage: review
kind: parallel
role: reviewer
spawn:
  - { task: "Check correctness vs spec", skillTags: [review, compliance] }
  - { task: "Check security",             skillTags: [review, security] }
  - { task: "Check architecture",         skillTags: [review, architecture] }
resultContract: reviewer-findings@1
reduceWith: probe.summarize         # or a named reducer
maxRounds: 3
passWhen: ".criticalCount == 0 and .majorCount == 0"
produces: [review]
escalation:
  need_decision: ask_user
```

And a composition sketch:

```yaml
playbook: delivery-flow
stages:
  - { delegate: spec-writing,  produces: [spec] }
  - { delegate: plan-writing,  requires: [spec], produces: [plan] }
  - { delegate: implementing,  requires: [plan], produces: [diff] }
  - { delegate: reviewing,     requires: [diff], produces: [review] }
  - { delegate: finishing,     requires: [review] }
```

Each delegated playbook is independently invokable. The shapes above are
illustrative of the capabilities in §7.2.1; the concrete schema is fixed in
the implementation slice that introduces playbooks (Slice 5).

---

## 8. Subagent lifecycle

```
queued → starting → running ──┬──► complete
                              │
                              ├──► blocked_on_parent  (decision.request open)
                              │       │
                              │       └─► running
                              │
                              ├──► blocked_on_user    (parent escalated)
                              │       │
                              │       └─► running
                              │
                              ├──► paused             (control.pause)
                              │       │
                              │       └─► running
                              │
                              ├──► terminating        (control.terminate)
                              │       │
                              │       └─► terminated
                              │
                              ├──► interrupted        (orchestrator restart)
                              │
                              └──► failed
```

Invariants:
- A child may only enter `complete` from `running`.
- A child in `blocked_on_parent` must have exactly one open `decision.request`.
- `terminated`, `interrupted`, and `failed` are terminal; no further events
  accepted from that child after the next heartbeat boundary.
- Heartbeat absence past `heartbeatTimeoutMs` flips state to
  `needs_attention` *for the sidecar* but does not auto-terminate.

---

## 9. Decision requests

A decision request is a typed, blocking ask from child to parent.

```ts
type DecisionRequest = {
  kind:
    | "need_decision"
    | "need_clarification"
    | "need_approval"
    | "need_secret"
    | "scope_boundary_hit"
    | "conflict_detected"
    | "blocked";
  question: string;                 // human-readable, ≤ 500 chars
  why: string;                      // why it's blocking, ≤ 500 chars
  options?: Array<{
    id: string;
    label: string;
    consequence: string;
  }>;
  recommended?: string;             // option id
  default?: string;                 // option id, used if policy auto-answers
  ttlMs?: number;                   // optional; child gives up after ttl
  context?: { artifactId?: string; ref?: string };
};
```

Parent policy for handling a request (in order):

1. **Auto-answer from cache.** If an identical `(role, kind, question hash)`
   was answered earlier this run with `rememberForRun: true`, reuse it.
2. **Auto-answer from policy.** If the parent has a role-policy rule
   matching this kind, apply it.
3. **Parent decides.** If the orchestrator can answer from its own context
   without involving the user, it does.
4. **Escalate to user.** Surface to the user as a structured prompt
   (in pi, via `ask_user_question` or a sidecar action).

A decision is resolved by `decision.reply { requestId, chosenOptionId?,
text?, rememberForRun? }`. The reply unblocks the child.

Important: late-delivered duplicate `decision.request` events with the
same `requestId` are deduplicated by the broker and never re-surfaced.
(Fixes the noisy "ghost ask" repeats seen in the smoke test.)

### 9.1 Multi-turn dialogue

A single mission may need more than one round-trip with the parent (or via
the parent, with the user). The shape is N sequential `decision.request` /
`decision.reply` pairs, not a chat channel:

- After emitting a `decision.request`, the child enters `blocked_on_parent`
  and stays there until the matching `decision.reply` arrives.
- On receiving the reply, the child returns to `running` and may emit another
  `decision.request` immediately. Each request is independent, has its own
  `requestId`, and is independently deduplicated.
- The child accumulates its own context across rounds; the parent's transcript
  does not. The parent's role per round is to inspect the request, apply
  policy, and either auto-answer, decide, or surface a single structured
  prompt to the user.
- A request may carry `followUpHint: true` to tell the parent "more rounds
  are likely"; this is a sidecar/UX hint only and does not change semantics.
- There is no `child → child` channel and no free-form chat surface. If a
  stage genuinely needs multi-turn dialogue with the user (a brainstorm,
  a clarification loop, a finishing choice), it expresses that as a chain
  of typed decision requests, each with `options[]` or free-text answers.

This means "conversational stages" do not require a special mechanism. A
brainstorm role is just a child that keeps issuing `need_clarification`
requests until it has enough to write its artifact and `complete`. The parent
remains the single conversational authority with the user; the child never
speaks to the user directly.

---

## 10. Probes

Children may **not** spawn other children. They may invoke probes.

Two classes:

### 10.1 Deterministic probes (no LLM)

Cheap, predictable, no model cost. Implemented as native functions
inside the extension.

Initial set:

- `probe.search { query, paths?, maxFiles, outputSchema }`
- `probe.fileMap { roots, depth?, include?, exclude? }`
- `probe.grepCluster { pattern, paths?, maxMatches, clusterBy }`
- `probe.gitDiff { range?, paths? }`
- `probe.gitBlame { file, lineRange }`
- `probe.runCommand { cmd, timeoutMs, captureBytes }` (read-only allowlist)
- `probe.readSlices { file, ranges }` (no full-file dumps)

### 10.2 LLM probes (mini-agents)

Short-lived constrained LLM calls. Always:

- single turn, no tool loop
- fixed prompt template, no system-prompt overrides from caller
- bounded input tokens and output tokens
- fixed output JSON schema
- no further delegation, no user asks, no parent asks

Initial set:

- `probe.summarize { input, schema, maxOutputTokens }`
- `probe.classify { input, labels, maxOutputTokens }`
- `probe.extract { input, jsonSchema }`
- `probe.compareEvidence { a, b, criteria }`

Hard rules for all probes:

| Rule | Reason |
|------|--------|
| No writes | Probes are evidence, not changes. |
| No user prompts | Only parent talks to user. |
| No parent prompts | Probes return failure on missing info; subagent decides whether to escalate. |
| No nested probes | Prevents recursion. |
| Bounded budget | Caller must declare `maxFiles`/`maxBytes`/`maxTokens`. |
| Schema-shaped output | Caller picks a known schema; output is validated. |

Every probe invocation is recorded as `probe.invoked` in events.jsonl
(audit only — not surfaced to parent context).

---

## 11. Public API

The parent receives one extension tool, `team`, with sub-actions. Shape
modeled on `pi-subagents` but explicitly structured.

```ts
team({ action: "spawn", agent: {
  role: "reviewer",
  task: "Review the current diff for correctness.",
  model: "anthropic/claude-haiku-4",       // optional override
  contextBudget: 200_000,                   // tokens
  tools: ["read", "grep"],                  // optional override
  writeAccess: false,                       // forced false for reviewer role
  worktree: false,                          // for worker roles only
  timeoutMs: 600_000,
  policy: { onDecisionKind: { "need_decision": "ask_user" } }
}})

team({ action: "status" })                      // compact snapshot
team({ action: "status", agentId: "reviewer-1" })

team({ action: "send", agentId, message })      // instruction event
team({ action: "reply", requestId, chosenOptionId?, text?, rememberForRun? })

team({ action: "pause", agentId })
team({ action: "resume", agentId, message? })
team({ action: "terminate", agentId, reason? })

team({ action: "summarize", agentId })          // compact summary, no full logs
team({ action: "artifact", agentId, name })     // returns reference, not body
team({ action: "artifact.read", artifactId, slice? })  // explicit content fetch

team({ action: "decisions" })                   // open decision requests
team({ action: "policy.set", role, kind, policy })

team({ action: "run.list" })                    // current run + recent runs
team({ action: "run.attach", runId })           // attach to persisted run state
```

Return shape rules:
- Default returns are **summary-shaped**, never raw outputs.
- All references to large data are `{ artifactId, bytes, lines, summary }`.
- `artifact.read` is the only path to raw content, and it is **explicit**.

---

## 12. Subagent (child) API

Children receive a constrained toolset injected by the extension. They do
not get the `team` tool.

```ts
escalate({                              // creates a decision.request
  kind: "need_decision",
  question: "...",
  why: "...",
  options: [...],
  recommended: "..."
})

progress({ message })                   // ≤ 200 chars

artifact.write({ name, kind, content }) // returns artifactId
artifact.list()

probe.search(...)
probe.fileMap(...)
probe.summarize(...)
... (see §10)

complete({ summary, findings?, artifactRefs? })  // mission complete
fail({ reason, artifactRefs? })
```

Children also get their role's standard pi tools (read, grep, etc.) filtered
by the role manifest. They **do not** get:

- `team` (parent-only)
- direct file writes outside their writeable scope
- `ask_user_question` (parent-only)
- intercom/messaging to other children
- the ability to spawn pi subagents

---

## 13. TUI sidecar panel

A pi extension TUI surface, rendered alongside the main transcript. Same
pattern as `pi-subagents/src/tui/render.ts` and `pi-intercom/ui`.

Default view (live, updates from `events.jsonl` tail):

```
╭─ Agent team ───────────────────────────────────────────────────╮
│ ID            role         model               state         ctx   activity │
│ scout-1       scout        sonnet-4.5          complete      8K/200K   12s  │
│ researcher-1  researcher   gemini-2.5-pro      running       32K/1M   now   │
│ reviewer-1    reviewer     haiku-4             blocked-user  20K/200K  3s   │
│ reviewer-2    reviewer     gpt-5.5             running       8K/272K  now   │
│ worker-1      worker       sonnet-4.5          paused        44K/200K  4m   │
╰────────────────────────────────────────────────────────────────╯
[d] decisions  [a] artifacts  [l] log  [t] terminate  [enter] focus
```

States surface as colors. `blocked-user` and `needs_attention` are
highlighted. Selecting a row drills into:

- last 50 events for that agent
- open decision requests
- artifact list
- ctx usage chart (simple sparkline)
- buttons: pause / resume / terminate / send instruction

Critical UX rule: **nothing in the sidecar enters the parent context window
unless the parent explicitly calls `team({ action: ... })`**. The sidecar
is a human surface, not a model surface.

---

## 14. On-disk layout

Per-run directory under `~/.pi/orchestration/runs/<runId>/` or
`<repo>/.pi/orchestration/runs/<runId>/` for project-scoped runs.

```
<runDir>/
├── run.json                  # run manifest: createdAt, parentSessionId, status
├── events.jsonl              # append-only event log
├── decisions/
│   ├── <requestId>.json      # open + resolved decisions
├── agents/
│   ├── <agentId>/
│   │   ├── manifest.json     # role, model, budget, tools, permissions
│   │   ├── session.jsonl     # child LLM session (pi-compatible)
│   │   ├── ctx.json          # last known ctx usage / heartbeat
│   │   └── log.txt           # raw stdout/stderr
├── artifacts/
│   ├── <agentId>/
│   │   ├── <name>            # the actual artifact content
│   │   └── <name>.meta.json  # kind, bytes, lines, summary
├── probes/
│   └── invocations.jsonl     # audit log
└── lock                      # pid lockfile for the orchestrator process
```

Why JSONL + filesystem:
- crash-safe, append-only event log
- trivial to tail for the sidecar
- trivial to recover state by replay
- no DB dependency

---

## 15. Persistence and recovery

MVP requirement: **recover run state across pi restarts, but do not reattach
live children.** If the orchestrator process dies, in-flight child work is
considered interrupted. The system goes back one step: preserve evidence,
show what was in progress, and require an explicit parent/user action to
retry, continue, or abandon the interrupted work.

On orchestrator startup:

1. Read `~/.pi/orchestration/runs/*/run.json` for runs whose parent session
   matches the current pi session OR whose `attachable: true`.
2. For each such run:
   - read `lock` — if pid is dead, the run is **recoverable**.
   - replay `events.jsonl` to reconstruct in-memory state.
   - for each agent in non-terminal state, mark it `interrupted` with reason
     `orchestrator_restart`; preserve `session.jsonl`, logs, ctx snapshots,
     and artifacts.
3. Re-emit all open `decision.request`s into the sidecar as unresolved run
   state. The parent may close, answer, or discard them explicitly.
4. Do **not** auto-post any of this to the user transcript. Surface via
   sidecar + optional one-line parent notification: "Recovered run X with
   2 interrupted agents and 1 open decision."

Hard guarantees:
- Artifacts are always recoverable.
- Decision history is always recoverable.
- Interrupted child sessions/logs are preserved for inspection or explicit
  retry, but no live process is reattached automatically.
- The orchestrator never silently re-runs a child without explicit parent
  or user action.

---

## 16. Coordination limits and safety boundaries

`pi-orchestration` is a coordinator, not the system security boundary. It
assigns role profiles at spawn time and enforces orchestration-specific rules
such as "children do not get the `team` tool" and "multiple writers should not
silently edit the same worktree." It does **not** replace normal pi guardrails,
path-protection extensions, permission prompts, sandboxing, or user policy.
Those remain authoritative for actual tool safety.

Per role, assigned by the orchestrator/runtime at spawn time:

- `writeAccess`: role intent; default false. External guardrails still decide
  whether any concrete write is allowed.
- `worktree`: used for coordination/isolation when writeable roles run.
- `tools`: intended child tool profile. This is context/capability shaping,
  not a complete security sandbox.
- `network`: intended role profile; actual network access remains subject to
  installed tools/extensions and system policy.
- `maxArtifactBytes`: per-agent artifact cap enforced by artifact storage.
- `maxProbeInvocations`: per-agent cap enforced by the probe runtime.
- `maxRuntimeMs`: orchestration timeout for child processes.
- `maxCostUsd`: soft warn + sidecar flag; optional configured hard stop.
- `secrets`: never injected into prompts; `need_secret` decision kind forces
  parent (and usually user) involvement.

A child may request expanded resources or permissions via typed escalation, but
it cannot grant them to itself. Single-writer policy is treated as coordination:
if a writeable agent is running, spawning another writeable agent in the same
worktree fails unless isolated worktrees are used.

---

## 17. Failure modes

| Failure | Detection | Behavior |
|---------|-----------|----------|
| Child OOM/crash | broker disconnect + dead pid | state → `failed`, artifacts preserved |
| Decision TTL exceeded | timer | child receives `fail` from broker; logged |
| Heartbeat timeout | timer | state → `needs_attention`, **no auto-terminate** |
| Schema-invalid event | broker reject | event quarantined to `events.invalid.jsonl`, agent warned |
| Duplicate decision id | broker dedupe | ignored, audit logged |
| Probe budget exceeded | probe runtime | probe returns `error: budget_exceeded`, child decides |
| Worktree dirty | spawn precheck | spawn fails fast with actionable error |
| Orchestrator restart mid-run | startup replay | non-terminal agents marked `interrupted` with reason `orchestrator_restart`; artifacts preserved |
| Two concurrent writers in same tree | spawn check | second spawn rejected |

No failure path causes silent loss of artifacts or decisions, and no restart
silently continues or reruns in-flight child work.

---

## 18. Verifiable acceptance criteria

Every requirement below must be observable from outside the system
(via events.jsonl, run state, sidecar output, or an automated test).

### Conversation isolation
- **AC-1.** No `decision.request`, `agent.state`, `agent.heartbeat`, or
  `agent.complete` event from a child causes any visible chat message
  unless the parent explicitly chooses to surface it.
  - *Test:* spawn 3 agents that each emit progress + complete. Assert the
    parent's transcript contains zero auto-inserted lines.

### Typed escalation
- **AC-2.** A child cannot ask the user directly. Any attempt routes
  through the parent.
  - *Test:* child agent attempts `ask_user_question` — call is rejected
    by the runtime injector.
- **AC-3.** Duplicate `decision.request` events with the same `requestId`
  are deduplicated and never re-surface.
  - *Test:* fire the same request twice; sidecar shows one entry.

### Context protection
- **AC-4.** Default returns from `team({ action })` never include raw
  artifact bodies larger than 4 KB; bodies must be fetched via
  `artifact.read`.
  - *Test:* spawn a researcher that writes a 200 KB artifact. Parent's
    inbound tool result contains only a reference + summary.
- **AC-5.** `events.jsonl` and `log.txt` are never appended to the parent's
  prompt automatically.

### Per-agent independence
- **AC-6.** Two agents in the same run may use different models and
  context budgets; the sidecar reports each independently.
  - *Test:* spawn reviewer with haiku and reviewer with gpt-5.5; sidecar
    rows show distinct model + ctx columns.

### Probes are bounded
- **AC-7.** No probe may invoke another probe.
  - *Test:* probe attempts nested probe call → runtime error.
- **AC-8.** No probe writes to disk outside its artifact slot, and only
  reducers/extractors return >4 KB.
  - *Test:* attempt write outside slot → error.

### Lifecycle and control
- **AC-9.** `terminate` moves a child from any non-terminal state to
  `terminated` within 5 s and stops further event emission.
  - *Test:* spawn long-running child, terminate, assert no further events
    after a 5 s window.
- **AC-10.** Soft `pause` halts the current child turn but preserves
  session state; `resume` continues without re-prompting.

### Persistence
- **AC-11.** Killing the orchestrator process mid-run and restarting it
  recovers all artifacts and decisions for that run; all non-terminal agents
  are marked `interrupted` with reason `orchestrator_restart`, with sessions
  and logs preserved.
  - *Test:* spawn 3 agents, kill parent, restart, assert event log integrity,
    state reconstruction, and no automatic child continuation.
- **AC-12.** No restart silently re-runs or continues any agent.

### Sidecar
- **AC-13.** Sidecar reads only `events.jsonl` and on-disk state; it
  does not call the LLM and does not mutate run state except via
  explicit user actions in the panel.
- **AC-14.** Every transition in §8's state machine is reflected in the
  sidecar within 1 s of the corresponding event.

### Coordination and safety boundaries
- **AC-15.** Concurrent writeable agents in the same worktree are refused at
  spawn time unless isolated worktrees are requested.
- **AC-16.** A child is not given orchestration spawn primitives (`team`,
  parent-only commands, or direct child-spawn APIs).
  - *Test:* inspect child runtime tools and attempt to call `team` from a child
    role → runtime error.

### Multi-turn dialogue
- **AC-17.** A single child mission can issue N sequential `decision.request`s,
  each independently resolved, without the parent's transcript receiving any
  auto-inserted line beyond what the parent explicitly chooses to surface.
  - *Test:* spawn a brainstorm-style child that emits 5 `need_clarification`
    requests answered via cached policy. Assert 5 request/reply pairs in
    `events.jsonl` and zero auto-inserted user-facing lines.

### Skill inheritance
- **AC-18.** A child's runtime sees exactly the skills resolved at spawn time
  from its role manifest's `skills:` field (inherit + tag filter, explicit
  list, or none); skill discovery never runs inside the child.
  - *Test:* spawn a `reviewer` role with `skills: { inherit: true, tags:
    [review] }`. Inspect the child's injected system prompt and assert it
    contains exactly the parent-visible skills tagged `review`.

### Playbooks
- **AC-19.** A playbook can be invoked standalone or via delegation from
  another playbook; both paths produce identical artifacts and event logs for
  the delegated portion (modulo timing fields and `parentEventId` linkage).
- **AC-20.** A playbook stage with declared `produces:` artifacts is skipped
  when those artifacts already exist and pass the stage's validity check.
- **AC-21.** A playbook composition cycle is rejected at load time, not at
  run time.

---

## 19. Incremental delivery plan

The full spec is intentionally broad. Build it in slices where each slice is
useful on its own and keeps the parent context cleaner than today's delegation.

### Slice 0: headless spawn + artifacts
- One `team` tool with `spawn`, `status`, `summarize`, and `artifact.read`.
- Roles: `scout` and `reviewer` only.
- Event log: `agent.spawned`, `agent.state`, `agent.complete`, `agent.failed`,
  `artifact.written`.
- Child outputs default to artifact refs + compact summaries, not inline dumps.
- No sidecar, no probes, no decision queue yet.

### Slice 1: typed decisions
- Add `decision.request` / `decision.reply`.
- Parent can answer, cache for run, or escalate to user.
- Duplicate decision IDs are deduped.
- Children still cannot ask the user directly.

### Slice 2: recovery, status, and lifecycle control
- Persist full run state and recover it after restart.
- Mark non-terminal agents `interrupted` on orchestrator restart; never reattach
  or auto-rerun.
- Add `pause`, `resume`, `terminate`, heartbeat, and timeout handling.
- Add `team({ action: "decisions" })` and richer `status`.

### Slice 3: sidecar UI
- Read-only live panel backed by `events.jsonl`.
- Drill-down for last events, open decisions, and artifacts.
- Optional buttons for pause/resume/terminate/send instruction.

### Slice 4: probes and reducers
- Deterministic probes: `search`, `fileMap`, `grepCluster`, `readSlices`,
  `gitDiff`.
- LLM probes: `summarize`, `extract`.
- Probe outputs are schema-shaped and budgeted.

### Slice 5: orchestrator playbooks
- Markdown playbooks under `<repo>/.pi/orchestration/playbooks/` and
  `~/.pi/orchestration/playbooks/` with `project > user > builtin` precedence.
- Capabilities from §7.2.1: stage sequencing, stage-skip on existing
  artifacts, bounded loops with jq-style exit predicates, parallel fan-out
  with combine rules, structured result contracts, per-stage escalation
  policy, named artifact references, entry/exit contracts, conditional
  stages.
- **Composition** (§7.2.2): a stage may delegate to another playbook in the
  same run; cycles rejected at load time.
- Parent defaults to minimum necessary context when a playbook omits a schema.
- Skill inheritance (§7.1) is already live from earlier slices — playbooks
  override `skills:` per spawn but do not implement discovery themselves.

### Later
- `worker`, `researcher`, `planner`, and `context-builder` roles once the core
  control plane is stable.
- Per-role policy editor in sidecar.
- `compareEvidence`, `classify` probes.
- `team.attach` to attach to an external pi session's persisted run state.
- Cross-machine orchestration over signed sockets.
- Cost dashboards.
- Plan-mode integration: run reads/writes its plan as artifacts the parent
  edits across iterations.

---

## 20. Package layout (proposed)

Mirrors pi extension conventions seen in `pi-subagents` and `pi-intercom`.

```
pi-orchestration/
├── package.json
├── README.md
├── install.mjs
├── src/
│   ├── extension/
│   │   └── index.ts                # pi entrypoint, registers team tool + sidecar
│   ├── broker/
│   │   ├── broker.ts               # parent broker
│   │   ├── client.ts               # child broker client
│   │   ├── framing.ts              # length-framed JSON
│   │   ├── events.ts               # event types + zod/typebox schemas
│   │   └── paths.ts                # run directories
│   ├── runs/
│   │   ├── manager.ts              # spawn/lifecycle
│   │   ├── persist.ts              # events.jsonl, decisions, artifacts
│   │   ├── recover.ts              # restart-time state recovery
│   │   └── state.ts                # in-memory state machine
│   ├── roles/                      # builtin role manifests
│   ├── playbooks/                  # parent orchestrator workflow manifests
│   ├── probes/
│   │   ├── deterministic/          # native probes
│   │   └── llm/                    # mini-LLM probes
│   ├── child/
│   │   ├── runtime.ts              # tools injected into children
│   │   ├── escalate.ts
│   │   └── artifact.ts
│   ├── tui/
│   │   ├── sidecar.ts              # pi TUI panel
│   │   └── render-row.ts
│   └── shared/
│       ├── ids.ts                  # ULID
│       └── budget.ts
├── agents/                         # role markdown manifests (user-installable)
├── playbooks/                      # orchestrator playbooks (user-installable)
├── prompts/                        # /team slash command(s)
└── skills/
    └── pi-orchestration/SKILL.md   # parent-only orchestration skill
```

Skill scoping rule (same as pi-subagents): the orchestration skill is
injected into the **parent** session only. Children never see it.

---

## 21. Open questions (small, tractable)

1. **Budget enforcement** — soft warn vs hard kill on `maxCostUsd`. MVP
   proposal: warn in sidecar at 75 %, hard-stop at 100 % unless role
   overrides.
2. **Sidecar focus model** — does focusing an agent in the sidecar pause
   the orchestrator's turn? Proposal: no, sidecar is fully out-of-band.
3. **LLM probe model selection** — fixed per probe, or inherited from
   caller? Proposal: each LLM probe declares its own preferred model
   with a cheap default; caller may override only from an allowlist.
4. **Plan-mode interop** — should the orchestrator gate writeable
   children behind pi's plan mode? Proposal: yes when plan mode is
   active; refuse `worker` spawns until plan is approved.
5. **Run scoping** — should runs default to project (`.pi/orchestration`)
   or user (`~/.pi/orchestration`)? Proposal: project-scoped when inside
   a repo, user-scoped otherwise; manifests record the choice.

None of these block MVP; each has a stated default.

---

## 22. Out of scope to discuss now

- Token accounting integration with pi's billing model.
- Sharing runs across users.
- A web UI for the sidecar.
- Importing pi-subagents agents directly. (They can be re-authored as
  pi-orchestration roles; that path is straightforward but not in MVP.)

---

## 23. Summary

`pi-orchestration` is the structured agent-team substrate the smoke test
proved we need but couldn't get from chat-bound primitives. It keeps the
parent's context clean by routing all control traffic through typed events
and a sidecar, keeps children focused via probes and reducers, and stays
verifiable through the AC list in §18.

If §18 passes, the system works.
