# Git Workflow Guide

This project uses **Gitflow** for version control. This guide explains the branching strategy and common workflows.

## Branch Strategy

### Main Branches

| Branch | Purpose | Protected |
|--------|---------|-----------|
| `main` | Production-ready releases | Yes |
| `develop` | Development integration | Yes |

### Supporting Branches

| Branch Type | Naming | Base | Merges Into |
|-------------|--------|------|-------------|
| Feature | `feature/<name>` | `develop` | `develop` |
| Release | `release/<version>` | `develop` | `main` & `develop` |
| Hotfix | `hotfix/<name>` | `main` | `main` & `develop` |

## Visual Overview

```
main        ●─────────────────────●─────────────●───────
            │                     ↑             ↑
            │                     │             │
            │              release/1.0    hotfix/1.0.1
            │                     ↑             ↑
            ↓                     │             │
develop     ●────●────●────●──────●──────●──────●────●──
                 │    ↑    │             ↑
                 │    │    │             │
                 ↓    │    ↓             │
            feature/A │  feature/B       │
                      │                  │
                 (merged)           (merged)
```

## Workflows

### 1. Feature Development

#### Start a Feature

```bash
# Ensure develop is up to date
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/calendar-improvements
```

#### Work on Feature

```bash
# Make changes and commit
git add .
git commit -m "feat(calendar): add week view navigation"

# Push to remote
git push -u origin feature/calendar-improvements
```

#### Complete Feature

```bash
# Update with latest develop
git checkout develop
git pull origin develop
git checkout feature/calendar-improvements
git rebase develop

# Create pull request on GitHub
# After review and approval, merge via GitHub UI

# Clean up
git checkout develop
git pull origin develop
git branch -d feature/calendar-improvements
git push origin --delete feature/calendar-improvements
```

### 2. Release Process

#### Start a Release

```bash
# Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/1.0.0

# Update version numbers, documentation
# Commit changes
git commit -m "chore(release): bump version to 1.0.0"
git push -u origin release/1.0.0
```

#### Finalize Release

```bash
# Merge into main
git checkout main
git pull origin main
git merge --no-ff release/1.0.0
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin main --tags

# Merge back into develop
git checkout develop
git merge --no-ff release/1.0.0
git push origin develop

# Clean up
git branch -d release/1.0.0
git push origin --delete release/1.0.0
```

### 3. Hotfix Process

#### Start a Hotfix

```bash
# Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-crash-fix
```

#### Apply Fix

```bash
# Make fix and commit
git add .
git commit -m "fix(timer): prevent crash on nil date"
git push -u origin hotfix/critical-crash-fix
```

#### Complete Hotfix

```bash
# Merge into main
git checkout main
git merge --no-ff hotfix/critical-crash-fix
git tag -a v1.0.1 -m "Hotfix: critical crash fix"
git push origin main --tags

# Merge into develop
git checkout develop
git merge --no-ff hotfix/critical-crash-fix
git push origin develop

# Clean up
git branch -d hotfix/critical-crash-fix
git push origin --delete hotfix/critical-crash-fix
```

## Common Commands

### Daily Workflow

```bash
# Start of day - sync with remote
git checkout develop
git pull origin develop

# Check status
git status
git log --oneline -5
```

### Branch Management

```bash
# List all branches
git branch -a

# Delete local branch
git branch -d feature/old-feature

# Delete remote branch
git push origin --delete feature/old-feature

# Rename current branch
git branch -m new-name
```

### Undoing Changes

```bash
# Discard unstaged changes
git checkout -- <file>

# Unstage file
git reset HEAD <file>

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

### Viewing History

```bash
# Compact log
git log --oneline -10

# Graph view
git log --graph --oneline --all

# Show changes in commit
git show <commit-hash>

# Compare branches
git diff develop..feature/my-feature
```

## Best Practices

### Do

- Keep `main` always deployable
- Write descriptive commit messages
- Rebase feature branches before merging
- Delete branches after merging
- Tag all releases on main

### Don't

- Force push to `main` or `develop`
- Commit directly to protected branches
- Leave stale branches
- Create overly large pull requests
- Merge without code review

## Troubleshooting

### Merge Conflicts

```bash
# After conflict during merge
git status                    # See conflicting files
# Edit files to resolve conflicts
git add <resolved-file>
git commit                    # Complete merge
```

### Accidental Commit to Wrong Branch

```bash
# Move commit to correct branch
git checkout correct-branch
git cherry-pick <commit-hash>
git checkout wrong-branch
git reset --hard HEAD~1
```

### Sync Fork with Upstream

```bash
git remote add upstream <original-repo-url>
git fetch upstream
git checkout develop
git merge upstream/develop
git push origin develop
```
