# Process Manager

`discourse-workflow` provides a process management plugin for Discourse.

Discuss the plugin here: https://meta.discourse.org/t/discourse-workflow/347110?u=merefield

## Introduction

Process Manager provides a secure process-management framework for Discourse topics. Each process is made of configurable workflow steps and options, and topics move through those steps until completion. Some branching and looping is supported.

Using topics as work items gives each process a flexible, native Discourse foundation: each item can have a detailed description, attachments, discussion, notifications, tags, categories, permissions, and a full history out of the box.

If you are new to the terminology, see:

- Workflow: https://en.wikipedia.org/wiki/Workflow
- Business process: https://en.wikipedia.org/wiki/Business_process

## Features

- Process-management workflows using Discourse topics as work items
- Admin-defined processes made from steps mapped to Categories (or Sub-categories)
- Visual workflow editor for arranging steps, swim lanes, and transition connectors
- Transition actions presented as buttons per step option
- Permission model aligned to native Discourse category permissions
- Process discovery list (`/workflow`) with quick filters
- Process view selector in discovery (`List`, `Kanban`, `Chart`) when applicable
- Kanban view for compatible single-process lists
- Drag/drop transitions in Kanban with legal/illegal drop-zone highlighting
- Keyboard Kanban transitions on focused cards (`ArrowLeft` / `ArrowRight`) when legal
- Process-level Kanban tags toggle (`show_kanban_tags`, default `true`)
- Built-in process burn-down chart view (`/workflow/charts` and chart mode in `/workflow`) for single-process context
- Chart period selector (`1` to `12` weeks), complete-week windows (Sunday to Saturday), per-step colored series
- Overdue behavior with hierarchy:
  - global default (`process_manager_overdue_days_default`)
  - workflow override
  - step override
  - `0` disables overdue behavior at that scope
- Overdue indicator column in the process topic list
- Stale state transition handling with explicit user-facing error and automatic refresh
- Transition audit trail via small action posts
- Process visualization modal from topic and list links
- Data Explorer audit query support
- Data Explorer workflow stats query support for chart-oriented time series
- Optional AI-assisted step handling with prompt + option guardrails

## Quickstart

1. Enable the plugin in Site Settings (`process_manager_enabled`).
2. Go to `Admin -> Plugins -> Process Manager`, create a process, then save it.
3. Add workflow steps (Categories in journey order), then add step options (actions/transitions).
4. Create a topic in the first step Category and transition it through actions from the topic banner.
5. Use `/workflow` to view queue state, apply quick filters, and switch between `List` / `Kanban` / `Chart` views when available.
6. In Kanban, click a card to open the topic, drag cards to legal target steps, or use keyboard arrows on focused cards.
7. Use `/workflow/charts` (or `Chart` view in `/workflow`) to see step counts over time for the currently scoped single process.

## Setup

### Core plugin settings

- `process_manager_enabled`: enables/disables Process Manager behavior.
- `process_manager_overdue_days_default`: default overdue threshold in days; `0` disables overdue by default.
- `process_manager_openai_api_key`: API key for AI actions.
- `process_manager_ai_model`: model used for AI actions.
- `process_manager_ai_prompt_system`: system prompt support for AI transitions.
- `process_manager_charts_allowed_groups`: non-admin groups allowed to view process charts.

### Process definition setup

Process Manager is not bundled with a process; you create your own definitions.

The screens to create one are in `Admin -> Plugins -> Process Manager`.

First create a new process by hitting the button, save it, then populate it with steps by editing the process. Each step, once created, can be edited to add options, taken from a list of pre-defined options.

You can change the label of an Option in `Admin -> Customize -> Text`.

A good range of Options is seeded by default, but you can customize the text as needed.

Process-level Kanban controls:

- `show_kanban_tags`: controls whether tags render on Kanban cards below the title. Default is enabled.

### Overdue setup hierarchy

- Global default: `process_manager_overdue_days_default`
- Optional process-level override: `Workflow.overdue_days`
- Optional step-level override: `WorkflowStep.overdue_days`

Resolution order is `step -> workflow -> global`. A value of `0` means overdue behavior is disabled at that level.

### Kanban compatibility and behavior

Kanban view is shown when the current `/workflow` list is scoped to a single compatible process.

Compatibility requires:

- at least one step
- a single start step at position `1`
- unique step positions
- valid target step IDs
- all steps reachable from the start step
- unique directed transition mapping per step pair (`from_step -> to_step`)

For each directed edge, Kanban drag/keyboard transitions are option-agnostic and deterministic.

### Chart view behavior and access model

Chart view is shown when the current process discovery context resolves to a single process.

- Route support: `/workflow/charts` and chart mode in `/workflow` via `workflow_view=chart`
- View selector behavior: `Chart` is only shown when the user can view charts and the current discovery context is a single process
- Period selection: `1` to `12` weeks
- Time windows: complete weeks (Sunday through Saturday)
- Series: one line per step, color derived from step category color (or parent category color fallback)
- Response scope: chart payload includes selected process metadata (`selected_workflow_id`, `selected_workflow_name`) plus series data for that selected process context

Access model for charts is intentionally separate from topic-level category access:

- Admins can always view charts
- Users in `process_manager_charts_allowed_groups` can view charts
- Chart access is aggregate and process-level; it is intentionally not constrained to per-topic visibility rules
- This allows operational/reporting audiences to monitor process throughput without granting direct access to every underlying topic

If you want stricter chart data visibility, keep `process_manager_charts_allowed_groups` empty and rely on admin-only access.

### Background jobs

The plugin schedules and runs the following jobs:

- `Jobs::DiscourseWorkflow::DailyStats`: records daily process step counts
- `Jobs::DiscourseWorkflow::AiTransitions`: runs AI-enabled transitions
- `Jobs::DiscourseWorkflow::DataExplorerQueriesCompleteness`: ensures default Process Manager Data Explorer queries exist
- `Jobs::DiscourseWorkflow::TopicArrivalNotifier`: sends first-post arrival notifications on process transitions

### AI actions

You can leverage AI to handle a step. You need `process_manager_openai_api_key`, AI enabled on the step, and a prompt including both `{{options}}` and `{{topic}}`. You can also tune behavior with `process_manager_ai_model` and `process_manager_ai_prompt_system`.

Example prompt:

`your options are {{options}}. if the following text states it is delicious, please accept, otherwise reject. {{topic}} answer with one word from those options`

## Introductory Concepts

To leverage the Discourse platform as-is as much as possible, this plugin uses many existing core features.

## Swim Lanes

Each process swim lane is a Category (or Sub-Category).

As a process instance continues along its journey, it moves between Categories in a customizable but pre-defined journey.

## Process Instances

A single process instance (for example, a ticket) is a Topic. You can add tags to a Topic to highlight priority or other metadata. You cannot amend its Category once it has begun its journey other than by taking process actions upon the Topic.

## Actors

Any Group which has Topic creation access to a Category can act upon the topics in that Category.

Those that have Reply access can comment on the process item just as they can for a normal Topic.

You can hide Topics within a Category from specific groups in the normal way.

## Actions via Options

These are defined for each step when setting up the process. Actors can choose to take any available action as each Option is presented as a button on the Topic.

Actions on a Topic are captured in a Small Action Post to help users understand the journey of the Topic.

## Dashboard

A Topic Discovery filter `Processes` gives a list of process instances, with three presentation modes when available:

- `List`: sortable process topic list with process columns and quick filters
- `Kanban`: actionable card board for compatible single-process views
- `Chart`: step count trends over time for a single process

You should keep process Categories and ideally tags distinct, so you can also use those to filter for all process instances that are at a particular stage, or have a specific tag.

## Audit trail

A bundled Data Explorer query provides a basic audit report of a process instance journey.

Because Data Explorer queries can be exposed beyond Admin, you can choose who to show them to.

## Visualisation

There is a button on each process Topic that allows you to bring up a visualization of where the Topic is in its process.

This is also accessible from the process fields on the Processes discovery view.

## Major Differences In Behavior To Stock

- you can't create a new Topic in a Category that's beyond the first step of a process
- you can't change the Category of a Topic that is within a process
- only "Creators" can act upon a Topic in a process.

## Tips

- Consider making all steps for a particular process a Subcategory within a single Category. Whilst this isn't necessary it will allow you to simply filter for that Category using existing Discourse Category drop-down in the Discovery list to see all process instances for that specific process.
- In the new Processes discovery list you can click on Process, Position or Step to visualise where that instance is along its path.

## Roadmap Themes

Status legend:

- `Implemented`: shipped and production-usable
- `Partial`: available in a limited form; still needs first-class completion
- `Planned`: supported by architecture direction but not shipped yet
- `Missing`: not yet represented as a first-class capability

Permissioning principle:

- The plugin intentionally reuses core Discourse category permissions as the default and preferred model.
- Finer-grained step/action permission controls are lower priority so Process Manager stays simple to operate, easy for admins to reason about, and close to standard Discourse behavior.

| Area        | Capability                                                    | Status      | Notes                                                                      |
| ----------- | ------------------------------------------------------------- | ----------- | -------------------------------------------------------------------------- |
| Definition  | Process definitions (steps/options mapped to categories)      | Implemented | Core admin CRUD plus process-level display controls (for example `show_kanban_tags`) |
| Runtime     | Topic transitions with audit posts                            | Implemented | Transition actions are logged in-topic                                     |
| Discovery   | Process list with quick filters, list/kanban toggle, and step filtering | Implemented | `/workflow` supports SPA quick filters plus list/kanban switching          |
| Discovery   | Real-time process state-change notifier with refresh CTA      | Planned     | Wire MessageBus updates into `/workflow` with a core-style “press to refresh” flow |
| Kanban      | Card transitions (drag/drop and keyboard arrows)              | Implemented | Legal transitions only; deterministic directed edge mapping                |
| SLA         | Overdue thresholds (step -> workflow -> global, `0` disables) | Implemented | Includes overdue list indicator                                            |
| Permissions | Native Discourse category permissions for acting/commenting   | Implemented | Transition authority still aligns with category create access              |
| Permissions | Step/action-level transition permissions                      | Partial     | Deliberately lower priority to preserve simple, core-aligned permissioning |
| Validation  | Transition preconditions (required tags/fields/checks)        | Planned     | Intended as optional guardrails before transitions                         |
| SLA         | Escalation/reminder notifications                             | Partial     | Overdue visibility exists; automated escalation is next                    |
| Ownership   | Discourse Assign integration                                  | Planned     | Target is step-entry assignment and auditable ownership changes            |
| Operations  | Bulk process transitions from list views                      | Missing     | High-volume queue operation not yet first-class                            |
| Performance | Admin/list/chart/transition query-path N+1 and over-fetch hardening | Implemented | Admin serializers preloaded, process quick filters now SQL-scoped, chart loading scoped to selected process, transition lookup round-trips reduced, and workflow-state staleness indexing added |
| Performance | Bulk process arrival notification fan-out                     | Planned     | Use bulk insert (`insert_all`) for category watcher notifications to reduce per-user insert overhead at high watcher counts |
| Performance | Cache process chart payloads                                  | Planned     | Add short-lived caching keyed by process and period to reduce repeated chart aggregation for frequent refreshes |
| Performance | Cache process visualisation payloads                          | Planned     | Cache graph payloads keyed by topic/workflow-state version to avoid rebuilding identical visualisations |
| Performance | Production query-plan validation for process filters          | Partial     | Query shape is now SQL-driven; continue with `EXPLAIN`/index tuning against large production-like datasets |
| Reporting   | Built-in process analytics dashboards                         | Partial     | Data Explorer support exists; admin-native reporting is next               |
| Lifecycle   | Import/export/version process definitions                     | Missing     | Useful for staging->production promotion and rollback                      |
| Integration | Event hooks / webhooks / automation integration               | Planned     | Transition and step events are good integration points                     |
| AI          | Guardrailed AI-assisted transitions                           | Partial     | Present but should tighten confidence/fallback/audit behavior              |

### Priority Roadmap

1. Add MessageBus-driven process state-change notifications with a core-style refresh CTA in `/workflow`.
2. Add transition preconditions and clearer per-action validation feedback.
3. Add escalation automation (reminders/alerts) on top of existing overdue thresholds.
4. Add first-class reporting and assignment integration for operational processes.
5. Add definition lifecycle tooling (import/export/versioning) for safe environment promotion.
6. Keep advanced step/action permission granularity as a lower-priority enhancement to avoid unnecessary complexity versus native Discourse permissioning.
