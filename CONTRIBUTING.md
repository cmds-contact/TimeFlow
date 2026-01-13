# Contributing to TimeFlow

Thank you for your interest in contributing to TimeFlow! This document provides guidelines and workflows for contributing.

## Table of Contents

- [Git Workflow](#git-workflow)
- [Branch Naming](#branch-naming)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Code Style](#code-style)

## Git Workflow

This project follows the **Gitflow** workflow:

```
main          ─────●─────────────────●───────────── (production releases)
                   │                 ↑
                   │                 │ merge
                   ↓                 │
develop       ─────●────●────●───────●────●──────── (development)
                        │    ↑
                        │    │ merge
                        ↓    │
feature/xxx            ●────●                       (feature branches)
```

### Branches

| Branch | Purpose | Base | Merges Into |
|--------|---------|------|-------------|
| `main` | Production releases | - | - |
| `develop` | Development integration | `main` | `main` |
| `feature/*` | New features | `develop` | `develop` |
| `release/*` | Release preparation | `develop` | `main` & `develop` |
| `hotfix/*` | Production fixes | `main` | `main` & `develop` |

## Branch Naming

Use descriptive, lowercase names with hyphens:

```
feature/calendar-drag-drop
feature/task-estimation
bugfix/timer-crash-on-background
hotfix/data-loss-prevention
release/1.0.0
```

## Commit Messages

Follow the conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code restructuring |
| `test` | Adding/updating tests |
| `chore` | Maintenance tasks |

### Examples

```
feat(calendar): add drag-and-drop for time blocks

Implement drag gesture recognizer for PlanBlockView.
Blocks can now be moved and resized within the timeline.

Closes #12
```

```
fix(timer): prevent crash when app enters background

Store timer state before entering background.
Restore state when app becomes active.

Fixes #45
```

## Pull Request Process

### 1. Create Feature Branch

```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

### 2. Make Changes

- Write clean, well-documented code
- Add tests for new functionality
- Ensure all tests pass: `make test`

### 3. Commit and Push

```bash
git add .
git commit -m "feat(scope): description"
git push origin feature/your-feature-name
```

### 4. Create Pull Request

- Base branch: `develop`
- Provide clear description of changes
- Reference related issues
- Request review from maintainers

### 5. After Approval

```bash
# Maintainer merges PR into develop
# Delete feature branch after merge
git branch -d feature/your-feature-name
git push origin --delete feature/your-feature-name
```

## Code Style

### Swift Guidelines

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Keep functions focused and small
- Document public APIs with comments

### Architecture Rules

1. **UseCase Pattern**: UI should not call repositories directly
2. **Dependency Injection**: Use `@Environment` for dependencies
3. **Time Calculations**: Always use `Core/Time` module
4. **Models**: Keep SwiftData models in `Data/SwiftData/Models`

### File Organization

```swift
// MARK: - Properties

// MARK: - Initialization

// MARK: - Public Methods

// MARK: - Private Methods
```

## Questions?

Open an issue for questions or suggestions.
