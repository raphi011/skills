# Step 1: Forgotten Items Check

Review current changes against the plan/task to ensure nothing was missed.

1. Run `git diff main...HEAD` to see all changes
2. Check for:
   - Missing tests for new functionality
   - Unused code or dead code
   - Missing documentation updates (if adding new CLI flags/commands)
   - TODOs that should be addressed
   - Debug code that should be removed

If issues found, fix them before proceeding.
