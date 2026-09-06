# Execution plan

All tasks are pending. Mark complete only with recorded evidence. Each task should produce a focused diff and a short explanation of what changed, what was checked, and remaining limitations.

| Task | Work | Completion evidence |
| --- | --- | --- |
| T01 | Inspect available environment; create minimal iOS alarm prototype; verify brief sound/vibration-only and scheduling options | docs/FEASIBILITY.md updated with SDK references and actual device results; unresolved requirements identified |
| T02 | Refine SPEC.md using T01 results | Supported behavior and acceptance criteria explicit; material requirement changes reviewed with user |
| T03 | Finalize architecture and dependencies | Document recurrence strategy, scheduling limits, partial failures, and permission handling |
| T04 | Create application foundation and local model/storage | Configuration persists across relaunch; actual build instructions in README |
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
