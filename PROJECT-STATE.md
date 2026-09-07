# Project State — General 5

Снимок состояния: 2026-09-07
Репозиторий: Alexio00/Orchestration
Ветка: main
Ревизия артефактов: 8a41fabd6d36787b5044f64589f36eeeacf6f63f
База снимка: 3398f355eb6d6c4f9d1b836bfdfdda9c82965774
Текущий HEAD: проверяется при чтении
Активная версия General: 5.0.0 — released
Bootstrap и Cloud Adapter: 1.2.1 — integrated, released, published; activation не подтверждён
Рабочий candidate: Bootstrap и Cloud Adapter 1.2.2
Ревизия снимка: 13

## Цель

Развивать General 5 как компактный PM-оркестратор и обеспечить переносимую, проверяемую активацию правил и состояния проекта в основных нейросетевых средах.

## Границы текущего этапа

- Входит: lifecycle, ревизии состояния, immutable tag-gate, troubleshooting, навигация и сокращение контекста.
- Не входит: остальные findings; изменение General 5.0.0; пересмотр `KNOWN-FEATURES.md`; живая активация.
- Ограничение: snapshot 1.2.1 не переписывается; изменения выпускаются как candidate 1.2.2.
- Критерий готовности: один lifecycle, устойчивый state, tag-gate, recovery, компактный контекст и зелёные проверки.

## Ключевые решения PO

- General 5.0.0 и тег `v5.0.0` неизменны.
- Lifecycle: `draft → verified → integrated → released → published → activated`; установка не равна активации.
- Bootstrap готовит только файлы активации, ветку и один draft PR; merge, публикация и live-тест требуют отдельных решений.
- Первоначальный запуск Codex/Qwen без `AGENTS.md`, trust boundary и глобальная область разрешения cloud-адаптера остаются принятыми особенностями.
- 2026-09-07 — PO разрешил исправить пять рекомендаций последнего аудита документации.

## Завершено

- General 5.0.0 выпущен и совпадает с тегом `v5.0.0`.
- Bootstrap/Cloud Adapter 1.2.1 опубликованы snapshot `v5.0.0-bootstrap-1.2.1-cloud-1.2.1` из `8a41fabd6d36787b5044f64589f36eeeacf6f63f`.
- Версия 1.2.1 сохраняет позицию managed-блока и проверяет activation PR по marker, полному changed-files и head-tree.
- Последний state-only merge: PR #4, commit `3398f355eb6d6c4f9d1b836bfdfdda9c82965774`.

## Текущее состояние

Версия 1.2.1 опубликована, но не активирована в пользовательских окружениях. Candidate 1.2.2 устраняет пять документационных findings и добавляет tag-gate; General 5.0.0 и принятые особенности не изменяются.

## Открытые вопросы

- Пройдёт ли candidate 1.2.2 проверку и получит ли решения PO о merge и публикации?
- Подтвердит ли новая сессия Claude Code Cloud установку, recovery и квитанцию?
- Подтвердят ли ChatGPT, Codex и Qwen Code загрузку постоянных точек входа?

## Следующий шаг

Проверить candidate 1.2.2 в draft PR. После решения PO — merge и публикация; затем отдельный live-тест Claude Code Cloud.

## Контекст следующего шага

- `README.md` и `ACTIVATION.md` — lifecycle, навигация и troubleshooting.
- `ACTIVATION-BOOTSTRAP.md` и `PROJECT-STATE.template.md` — модель ревизий.
- `scripts/verify-artifacts.sh` и `.github/workflows/verify.yml` — tag-gate.
- `PROJECT-STATE.md` — компактность и ближайший шаг.

## Справочный контекст

- `GENERAL-5.md` — ядро; читать только для проверки равенства.
- `KNOWN-FEATURES.md` — принятые особенности.
- Исследование сред — исторические основания, не текущая спецификация.
- Публикационный контур — только при выпуске или диагностике.

## Внешние изменяемые факты

- До изменений `main` был `3398f355eb6d6c4f9d1b836bfdfdda9c82965774`; текущий HEAD всегда перепроверять.
- Публичный manifest указывает snapshot 1.2.1 и source revision `8a41fabd6d36787b5044f64589f36eeeacf6f63f`; перепроверять перед публикацией.
- Загрузка инструкций средами требует live-теста.

## Риски и расхождения

- Candidate 1.2.2 не integrated/released/published/activated.
- PROJECT-INSTRUCTIONS должен оставаться в лимите 8000 символов.
- Недоступность релизного тега должна блокировать проверку выпущенного General.

## Свежесть снимка

Ревизия артефактов фиксирует продукт; база снимка — HEAD до записи. Текущий HEAD определяется при чтении. State-only commit не создаёт drift артефактов; другие commits требуют оценки.

## Правило обновления

Обновляй файл только при значимом checkpoint.
