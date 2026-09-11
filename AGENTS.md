# Additional Conventions Beyond the Built-in Functions

As this project's AI coding tool, you must follow the additional conventions below, in addition to the built-in functions.

# Agent Behaviour
* Prefer existing DU capabilities before creating new mechanisms.
* Prefer the smallest solution that satisfies the task.
* Do not introduce new infrastructure without evidence that the existing architecture is insufficient.
* Do not silently work around persistent DU problems.
* When a recurring or architecturally meaningful problem is discovered, record it through the existing DU lifecycle when appropriate.
* Prefer regression tests before introducing new infrastructure for recurring technical problems.
* Preserve useful historical information when changing architecture.
* Do not delete historical knowledge merely because it is no longer current.

# Agent Configuration
* Rulesync is the central distribution layer for agent-facing configuration.
* Rulesync-generated configuration is derived and reproducible.
* Generated agent configuration is not an independent source of truth.
* Use Rulesync for the agent-facing capabilities it supports, including rules, skills, commands/workflows, subagents, MCP configuration, hooks, permissions, and other supported surfaces.
* Do not create competing hand-maintained configuration when a central Rulesync source exists.
* Do not copy canonical Project memory into agent configuration merely for convenience.
* Agent-native memory must not become a competing canonical DU memory system.

# Canonical Knowledge
* The Development Universe Vault is the canonical source of durable knowledge and Project state.
* Canonical knowledge includes Projects, Decisions, Knowledge, Patterns, Problems, Constraints, Sessions, Memory Candidates, and Registry data.
* Derived indexes and projections must never become competing sources of truth.
* Preserve provenance whenever durable knowledge is proposed or promoted.
* Prefer existing canonical knowledge over creating equivalent information.
* Do not create duplicate sources of truth.

# Context
* Obtain relevant DU context before substantial work when the workspace provides the DU integration.
* Use the DU Context Engine rather than manually reconstructing Project context from multiple sources.
* Context should be relevant to the current Project, task, workflow, and scope.
* Prefer concise, high-signal context over large amounts of historical material.
* The Context Engine may combine canonical Project State, durable knowledge, Sessions, semantic retrieval, and applicable code-graph information.
* Do not assume that every available piece of information belongs in the current context.
* Context retrieval should not mutate canonical knowledge.

# DU Identity and Scope
* A Project is the fundamental unit of work.
* A Repository is an operational workspace belonging to a Project.
* Resolve the current Repository and Project dynamically whenever the DU can do so.
* Do not infer Project identity from hard-coded paths or memory when the DU Registry can resolve it.
* Respect Project, Repository, global, and other declared scopes.
* Do not assume knowledge from one Project applies to another Project.
* The Development Universe itself is developed as a Project and its Reference Project is the primary self-hosting environment.

# Memory Governance
* The DU memory lifecycle is: Observation → Memory Candidate → Review → Canonical Memory.
* Agents may observe, classify, summarise, and propose durable knowledge.
* Canonical memory must not be established silently by an agent.
* Human governance remains authoritative for canonical promotion unless a specific explicit policy states otherwise.
* Preserve provenance from candidate to resulting canonical entity.
* Do not promote Project-specific knowledge to global scope without explicit justification and governance.
* Promoted candidates remain available for provenance/audit but should not compete with their canonical representation during normal retrieval.

# Architectural Pre-Flight Verification
* Before formulating or executing code changes, schema refactoring, or architectural modifications, agents MUST verify applicable canonical Decisions (`04-decisions/`) and Constraints (`08-system/constraints/`).
* Check the project-scoped and declared global constraints injected at Turn 0.
* When a proposed change appears to conflict with a canonical Constraint or Decision:
  - Do NOT silently bypass or ignore the constraint.
  - Surface the conflict explicitly as an Architectural Conflict.
  - Seek human confirmation or follow the canonical exception/amendment procedure.
* Never proceed with ungrounded architectural refactoring without verifying existing canonical invariants.

# Sessions
* Use the DU Session lifecycle when working in a DU-enabled Project.
* Start work with relevant Project context.
* Use the explicit Session ID returned by the DU when Session continuity is required.
* End substantial work with a Session reflection.
* Record meaningful outcomes, unresolved issues, and durable observations through the DU lifecycle.
* Do not recreate Session state through ad-hoc files or parallel memory mechanisms.

# State Model
* Canonical state is persistent and versionable.
* Derived state is rebuildable from canonical state.
* Runtime state is temporary execution state.
* Context Capsules are runtime state.
* Temporary retrieval results are runtime state.
* Session identity may be passed explicitly between processes without being stored in a hidden runtime cache.
* Runtime state must not become canonical knowledge merely because it exists during an agent session.
* Do not create persistent files merely to simulate runtime memory.

# Graphify
* Graphify is repository-local derived code intelligence.
* Apply Graphify to applicable software repositories.
* Do not apply Graphify to the Obsidian Vault merely because the Vault belongs to the Development Universe.
* Do not treat the entire Dev/ parent directory as a single Graphify workspace.
* Use Graphify inside the Repository boundary.
* Do not copy Graphify output into the canonical Vault.
* Use Graphify when code-structural relationships are relevant to the task.
* Do not treat Graphify as canonical memory.

# OpenSpec
* OpenSpec is the current standard workflow for software Projects unless the Project explicitly declares another workflow.
* Follow the Project's OpenSpec configuration and instructions.
* Use DU context to inform OpenSpec proposal, specification, design, task, implementation, and verification work.
* Keep OpenSpec artefacts separate from canonical DU memory.
* Do not automatically convert OpenSpec artefacts into canonical DU memory.
* Do not duplicate canonical DU memory into OpenSpec merely for convenience.
* When an OpenSpec task is completed, do not only check [x].
* Append a nested execution-log bullet directly beneath the completed task.
* Use exactly this format:
  - *Executed YYYY-MM-DD*: <Brief summary of what changed and any roadblocks>
* Preserve existing OpenSpec task history.

# Testing
* Separate unit, integration, end-to-end, and production-smoke testing where appropriate.
* Keep tests isolated from production .dev-cache/ state.
* Do not use the live production Vault as an implicit fixture for ordinary tests.
* Preserve real end-to-end coverage for critical pipelines.

# Universal Interaction
* Never leave a question entirely open-ended when user input is required. Provide at least three distinct numbered options plus a final Open Answer / Other option.
* Distinguish facts, assumptions, recommendations, and decisions.
* Surface relevant uncertainty instead of inventing missing context.
* When the required choice is minor and can safely be inferred, prefer a sensible default rather than interrupting the workflow.

## Three-Tier Tool Precedence Cascade
When interacting with the Development Universe, agents MUST follow this precedence cascade:
1. **Tier 1 — Native MCP Tools**: Prioritize native MCP tools (`dev-universe`, `obsidian`) when available in the agent harness.
2. **Tier 2 — Global CLI Dispatcher**: When MCP tools are unmounted or in CLI sessions, invoke the global engine wrapper (`dev.cmd` / `dev.ps1`).
3. **Tier 3 — Read-Only Vault Inspection**: Fall back to direct filesystem read tools only if engine interfaces are unavailable. Never perform ungrounded filesystem writes outside canonical boundaries.
