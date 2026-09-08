# Идея: Planning / Execution environments

Статус: **идея для исследования**.

Это не утверждённое изменение General 5, не решение PO о реализации и не элемент плана разработки.

## Контекст

В ходе анализа лимитов и возможностей ChatGPT и Claude появилась идея разделить работу General/Orchestrator на два логических слоя:

1. **Planning** — исследование, анализ, архитектура, принятие решений, декомпозиция и подготовка плана реализации.
2. **Execution** — изменение файлов/репозитория, запуск команд и тестов, создание веток/коммитов/PR, выполнение плана.

Цель — сохранить **единый General/Orchestrator**, работающий в разных средах, но учитывать реальные возможности каждой среды.

## Основная идея

Не создавать отдельные версии General для Chat, Work, Claude Chat и Claude Code.

Вместо этого:

- **General** — единый протокол оркестрации.
- **Environment Adapter** — описание возможностей конкретной среды.

Ориентировочная модель:

```text
                 GENERAL
                    │
          Orchestration Protocol
                    │
        ┌───────────┴───────────┐
        │                       │
   OpenAI Adapter          Claude Adapter
        │                       │
   ┌────┴────┐             ┌────┴─────┐
 Chat       Work          Chat      Claude Code
```

## Распределение ролей

### Chat

Основное назначение:

- research;
- анализ репозитория;
- архитектура;
- проектирование;
- сравнение вариантов;
- принятие решений совместно с PO;
- декомпозиция;
- implementation plan;
- review результатов;
- подготовка handoff для исполнительной среды.

Если workflow требует роли Architect / Researcher / Auditor и настоящие subagents недоступны, Chat может выполнять роль последовательно внутри текущего контекста.

Такое выполнение **не считать настоящим subagent execution**.

### Work / Claude Code

Основное назначение:

- исполнение утверждённого handoff;
- изменение репозитория;
- branch;
- implementation;
- tests;
- validation;
- commit;
- push;
- PR;
- другие действия, доступные исполнительной среде.

Исполнительная среда не должна повторно проводить архитектурное исследование, если handoff уже содержит утверждённое решение и не обнаружен блокер.

## Capability model

Предлагается формализовать три режима выполнения:

### DELEGATED

Задача передана настоящему отдельному агенту с отдельным контекстом.

### INLINE

Роль последовательно выполняется текущей моделью в существующем контексте.

### UNAVAILABLE

Требование нельзя корректно выполнить в текущей среде.

Особенно важно: INLINE не считать эквивалентом DELEGATED там, где требуется независимость проверки.

## Execution requirements

Не полагаться исключительно на способность модели самостоятельно определить возможности текущей среды.

Handoff может явно объявлять требования, например:

```yaml
execution:
  requires_git_write: true
  requires_parallel_subagents: false
  requires_independent_review: false
  requires_local_fs: false
  allow_inline_fallback: true
```

Environment Adapter сопоставляет эти требования со своими возможностями.

Если обязательное требование невозможно выполнить:

- не симулировать выполнение;
- вернуть UNAVAILABLE;
- указать необходимую capability/environment.

## Handoff contract

Planning-среда должна завершать утверждённое проектирование структурированным handoff:

```text
Goal
Baseline
Decisions
Scope
Non-scope
Implementation plan
Acceptance criteria
Validation
Execution requirements
Open issues
```

Handoff содержит **конечные утверждённые решения**, а не историю рассуждений.

## Transport

Транспорт handoff зависит от платформы и не должен быть частью общей логики General.

### ChatGPT

Предпочтительный кандидат:

```text
Chat
 → explicit WORK-HANDOFF
 → Project context
 → Work
```

Fallback:

```text
explicit handoff → Work
```

Надёжность автоматического восстановления handoff из Project context требуется проверить практически.

### Claude

Claude Code не получает контекст Claude Project/Chat детерминированно.

Предпочтительный transport:

```text
Claude Chat
 → HANDOFF.md
 → GitHub
 → Claude Code
```

GitHub является persistent source of truth.

## Предлагаемый общий workflow

```text
Research
   ↓
Architecture
   ↓
Planning
   ↓
HANDOFF
   ↓
Execution
   ↓
Testing / Validation
   ↓
Review
   ↓
Merge
```

Planning и Review преимущественно выполняются в Chat.

Execution выполняется Work / Claude Code.

## Что требуется исследовать перед реализацией

1. Проверить практически ChatGPT `Chat → Project context → Work`: насколько надёжно Work получает конкретный последний утверждённый handoff.
2. Проверить текущие capability adapters General 5 и определить минимальные изменения.
3. Определить, нужен ли постоянный `HANDOFF.md` или достаточно transient handoff для ChatGPT.
4. Спроектировать capability schema.
5. Проверить совместимость с существующим механизмом subagents General 5.
6. Не менять General до отдельного решения PO после исследования.

## Статус решения

Идея только зафиксирована для последующего рассмотрения и исследования.

Реализация, изменение General 5 и включение работы в план требуют отдельного решения PO.
