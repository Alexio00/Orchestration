# Project State — General 5

Снимок состояния: 2026-09-08
Репозиторий: Alexio00/Orchestration
Ветка: main
Ревизия артефактов: 41469498c97d91ffdee9f6dc7c7a960dd643e910
База снимка: 90c50131bccb46260ba91175eb234f4f4bee6de6
Текущий HEAD: проверяется при чтении
Активная версия General: 5.0.1 — released, published, activated; 5.0.2 — candidate remediation; 5.0.0 — archived
Bootstrap и Cloud Adapter: 1.2.4 — released, published, activated; 1.2.5 — candidate remediation; 1.2.3 — ошибочный snapshot непригоден
Ревизия снимка: 19

## Цель

Развивать General 5 как компактный PM-оркестратор и обеспечить переносимую, проверяемую активацию правил и состояния проекта в основных нейросетевых средах.

## Границы текущего этапа

- Входит: General 5.0.2 и Bootstrap/Cloud Adapter 1.2.5, закрывающие три Major и два оставшихся Minor независимого аудита.
- Не входит: автоматическое удаление Git-веток; пересмотр `KNOWN-FEATURES.md`; экспериментальные среды; merge, tag, Release, публикация и активация candidate.
- Ограничение: General 5.0.0, тег `v5.0.0` и прежние публичные snapshots неизменны.
- Критерий готовности: все пять findings закрыты кодом и regression-проверками; candidate проходит CI и новый независимый read-only review exact subject.

## Ключевые решения PO

- General 5.0.0 и тег `v5.0.0` неизменны.
- Lifecycle: `draft → verified → integrated → released → published → activated`; установка не равна активации.
- Bootstrap готовит только файлы активации, ветку и один draft PR; merge, публикация и live-тест требуют отдельных решений.
- Первоначальный запуск Codex/Qwen без `AGENTS.md`, trust boundary и глобальная область разрешения cloud-адаптера остаются принятыми особенностями.
- 2026-09-07 — PO разрешил исправить пять рекомендаций последнего аудита документации.
- 2026-09-07 — PO отдельно разрешил squash-merge PR #5 и автоматическую публикацию Bootstrap/Cloud Adapter 1.2.2.
- 2026-09-07 — PO поручил постмерджево обновить только PROJECT-STATE.md; merge этого обновления отдельно не разрешён.
- 2026-09-07 — PO решил не автоматизировать удаление веток: после merge оркестратор сообщает о необходимости ручного удаления и даёт прямую ссылку на source-ветку.
- 2026-09-07 — изменение выпускается как General 5.0.1; после его релиза General 5.0.0 становится архивным.
- 2026-09-08 — PO разрешил squash-merge PR #7 и подготовку release-коммита General 5.0.1.
- 2026-09-08 — PO сообщил, что проверка активации General 5.0.1 прошла.
- 2026-09-08 — тег и GitHub Release `v5.0.1` созданы на release-коммите; после отказа immutable gate PO разрешил remediation 1.2.4 без изменения General и тега.
- 2026-09-08 — PO подтвердил успешный тест опубликованных General 5.0.1 и Bootstrap 1.2.4 без заявленных расхождений.
- 2026-09-08 — PO поручил запустить независимые аудиты логики и промптов; аудит read-only и не включает автоматическое исправление findings.
- 2026-09-08 — PO поручил подготовить General 5.0.2 и Bootstrap/Cloud Adapter 1.2.5, закрыв три Major и два оставшихся Minor.

## Завершено

- General 5.0.0 выпущен и совпадает с тегом `v5.0.0`.
- Bootstrap/Cloud Adapter 1.2.1 опубликованы как исторический snapshot из `8a41fabd6d36787b5044f64589f36eeeacf6f63f`.
- PR #5 смержен методом squash; commit `bd6a5384b4d8f1f7f93df89e0b13a1366ee84a33`.
- Bootstrap/Cloud Adapter 1.2.2 опубликованы snapshot `v5.0.0-bootstrap-1.2.2-cloud-1.2.2`; verifier, публикация и Pages deploy успешны.
- Версия 1.2.2 унифицирует lifecycle, разделяет ревизии состояния, добавляет tag-gate, troubleshooting и компактную навигацию.
- PR #7 смержен методом squash; candidate General 5.0.1 и совместимые Bootstrap/Cloud Adapter 1.2.3 интегрированы в `main@a37a49d99038b57e0d2051084e3eb85428815f68`.
- Release-коммит смержен как `68cd87ed907b9c8063b4f1c49c1c4fe62a7642e6`; тег и GitHub Release `v5.0.1` указывают на него.
- Публикационный run `34200301172` остановлен immutable gate: snapshot с ID `v5.0.1-bootstrap-1.2.3-cloud-1.2.3` уже существовал из candidate revision `a37a49d99038b57e0d2051084e3eb85428815f68`.
- PR #9 смержен методом squash как `04cbc37762b3567358c357d86b4e9097c695e292`; released-status gate интегрирован.
- Snapshot `v5.0.1-bootstrap-1.2.4-cloud-1.2.4` опубликован из `04cbc37762b3567358c357d86b4e9097c695e292`; публичный manifest обновлён.
- PO подтвердил успешный тест General 5.0.1 / Bootstrap 1.2.4 после публикации.
- Независимые аудиты exact subject `04cbc37762b3567358c357d86b4e9097c695e292` завершены: критических findings нет; подтверждены три Major и три Minor, один Minor freshness закрыт state-only PR #10.
- PR #10 смержен как state-only commit `90c50131bccb46260ba91175eb234f4f4bee6de6`; post-merge CI успешен.

## Текущее состояние

General 5.0.1 и Bootstrap/Cloud Adapter 1.2.4 остаются активным выпуском. Candidate 5.0.2/1.2.5 подготовлен: добавлены отдельный merge-gate, безопасная классификация source-ветки, fail-closed публикация только из `main` со released-статусами всех компонентов, единственность managed-маркеров и согласованный candidate-status документации.

## Открытые вопросы

- Подтвердит ли независимый reviewer закрытие всех пяти findings на exact candidate subject?
- После verified candidate требуется отдельное решение PO на merge; release/tag/publication/activation остаются последующими отдельными gates.

## Следующий шаг

Провести независимый read-only review candidate General 5.0.2 / Bootstrap/Cloud Adapter 1.2.5 на exact subject после сохранения draft PR.

## Контекст следующего шага

- Candidate artifacts revision: `41469498c97d91ffdee9f6dc7c7a960dd643e910`; state-only commit после него drift артефактов не создаёт.
- Проверить `GENERAL-5.md`, lifecycle-статусы компонентов, `.github/workflows/publish-pages.yml`, `scripts/publish-pages.sh`, `scripts/verify-artifacts.sh` и regression-тесты.
- Проверить синхронность `AGENTS.md`, `PROJECT-INSTRUCTIONS.md`, setup payload и `ACTIVATION.md`; лимит Project Instructions — не более 8000 символов.
- `KNOWN-FEATURES.md` — принятые PO особенности, не дефекты без нового воспроизводимого основания.

## Справочный контекст

- `GENERAL-5.md` — ядро; читать только для проверки равенства.
- `KNOWN-FEATURES.md` — принятые особенности.
- Исследование сред — исторические основания, не текущая спецификация.
- Публикационный контур — только при выпуске или диагностике.

## Внешние изменяемые факты

- `main=90c50131bccb46260ba91175eb234f4f4bee6de6`; источник: GitHub branches API; `checked_at=2026-09-08`; повторять перед записью или аудитом нового subject.
- Snapshot `v5.0.1-bootstrap-1.2.3-cloud-1.2.3` содержит candidate source revision `a37a49d99038b57e0d2051084e3eb85428815f68`; источник: публичный manifest Orchestration Pages; `checked_at=2026-09-08`; повторять при изменении manifest или политики snapshots.
- Snapshot `v5.0.1-bootstrap-1.2.4-cloud-1.2.4` содержит source revision `04cbc37762b3567358c357d86b4e9097c695e292`, `publishedAt=2026-09-08T07:50:56Z`; источник: публичный manifest Orchestration Pages; `checked_at=2026-09-08`; повторять перед новым release или использованием публичного пакета как exact evidence.
- Live activation General 5.0.1 / Bootstrap 1.2.4 подтверждён PO; источник: сообщение PO 2026-09-08; `checked_at=2026-09-08`; повторять после изменения General, Bootstrap/Adapter или способа активации.

## Риски и расхождения

- Candidate ещё не прошёл независимый exact-subject review и не должен считаться verified, integrated, released, published или activated.
- GitHub-коннектор текущей среды не умеет удалять branch refs; ручное удаление остаётся действием PO.
- Candidate PROJECT-INSTRUCTIONS занимает 7954 из 8000 символов; запас мал, дальнейшие изменения требуют сокращения или новой границы.

## Свежесть снимка

Ревизия артефактов фиксирует продукт; база снимка — HEAD до записи. Текущий HEAD определяется при чтении. State-only commit не создаёт drift артефактов; другие commits требуют оценки.

## Правило обновления

Обновляй файл только при значимом checkpoint.
