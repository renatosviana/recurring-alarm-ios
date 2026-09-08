# Execution plan

Tasks are tracked below. Mark complete only with recorded evidence. Each task should produce a focused diff and a short explanation of what changed, what was checked, and remaining limitations.

| Task | Work | Completion evidence |
| --- | --- | --- |
| T01 | Inspect available environment; create minimal iOS alarm prototype; verify brief sound and silent-notification behavior and scheduling options | Complete for the revised current-release scope: sound and silent-notification behavior recorded; vibration-only deferred as unresolved; remaining device checks remain explicit |
| T02 | Refine SPEC.md using T01 results | Complete: current release supports sound alerts and silent notifications; vibration-only is deferred; recurrence requirements preserved |
| T03 | Finalize architecture and dependencies | Complete: dependency boundary, recurrence strategy, scheduling limits, partial failures, permission handling, and CI scope-contract validation documented |
| T04 | Create application foundation and local model/storage | Complete: Codable alarm model, UserDefaults-backed store, persistence/replacement/deletion tests, and iOS build/test instructions remain in README |
| T05 | Implement list and editor | Create/edit/delete and validate all supported schedule types |
| T06 | Integrate OS scheduling and permissions | Correct scheduled/error state; denied permissions handled; device smoke test |
| T07 | Implement recurrence and schedule replacement | Date boundary tests pass; edits/deletes leave no duplicate or stale schedules |
| T08 | Execute automated and physical-device test plan | Results recorded in docs/TEST_PLAN.md; no invented simulator/device equivalence |
| T09 | Install signed build on owner's iPhone | User verifies alarm behavior; signing/install instructions documented |
| T10 | Add macOS CI build and tests | Actual project scheme builds and tests; workflow demonstrated; secrets excluded |
| T11 | Prepare optional TestFlight distribution | Signed archive and release notes prepared; account prerequisites resolved; upload/release authorization obtained if needed |
| T12 | Add diagnostics and improvement workflow | Scheduling failures can be inspected; defects reproduced and checked before new release |

## Working agreement

Work one task at a time for learning and review. Agents may inspect, implement, and run available local checks within the current task. Report actual blockers after completing useful available work. Ask about material product tradeoffs, not routine implementation choices. Do not claim the app is released or reliable until the corresponding evidence exists.
