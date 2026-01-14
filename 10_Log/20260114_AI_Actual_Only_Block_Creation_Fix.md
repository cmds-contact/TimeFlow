---
created: 2026-01-14T1430
modified: 2026-01-14T1430
---
## Summary

Calendar의 Actual Only 모드에서 블록 생성 시 Actual 블록이 생성되도록 수정함.

## Why (왜)

#### 배경
Actual Only 모드에서 빈 슬롯을 클릭/드래그해도 블록이 보이지 않는 버그 발생. 원인은 `createBlock` 메서드가 항상 Plan 블록만 생성하고, Actual Only 모드에서는 Plan 블록이 화면에 표시되지 않기 때문.

#### 목적
displayMode에 따라 적절한 블록 타입을 생성하여 사용자 경험 개선.

## What (무엇을)

#### 작업 항목
- `CalendarView.swift`의 `createBlock(at:)` 메서드 수정
- displayMode에 따른 블록 타입 분기 로직 추가
  - Actual Only: `createActualBlock` UseCase 호출
  - Plan Only/Overlay: `createPlanBlock` UseCase 호출 (기존 동작 유지)

#### 결과물
- 수정된 `TimeFlow/Features/Calendar/Views/CalendarView.swift`
- Git commit: `0dcdf83`

## How (어떻게)

#### 진행 방법
1. Explore 에이전트로 Calendar 컴포넌트 및 블록 생성 로직 분석
2. 문제 원인 파악: createBlock이 항상 Plan 블록만 생성
3. Plan 에이전트로 구현 계획 수립
4. `createBlock` 메서드에 switch문 추가하여 displayMode별 분기 처리
5. Git commit 및 push

#### 진행 상태
완료
