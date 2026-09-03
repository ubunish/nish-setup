# CLAUDE.md

## Workflow

### Prompt Recognition

- Categorise Prompt
    A. Project Planning
    B. User Question
    C. Goal-Oriented Coding (`feature`, `fix`, `refactor`)
    D. Documentation
    E. Quick Task (`chore`)
- Run Category Workflow

### Category Workflow

A. Project Planning:
Write PLAN.md to folder root

B. User Question:
Answer like caveman

C. Goal-Oriented Coding:
1. Enter Planning Mode
2. User Iterates Plan
3. User Accepts Plan
4. Claude Works on `main` (Branch Only When Plan Asks)
5. Claude Delegate Agents in Parallel → Complete Tasks
6. Claude Commits Completed Tasks (Follow CONTRIBUTING.md > Coding Style)
7. Claude Pushes (Branch: PR → CI Green → Merge)
8. Claude + User Test Against Goal

D. Documentation
Follow CONTRIBUTING.md > Documentation

E. Quick Task
Run in terminal