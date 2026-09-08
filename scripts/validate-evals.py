#!/usr/bin/env python3
"""Проверяет контракт поведенческих сценариев, а не поведение агента.

Успешное выполнение сценария подтверждается отдельным run evidence со
ссылкой на trace; сама спецификация доказательством не является.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCENARIOS = ROOT / "evals/general-behavioral-scenarios-v2.json"
KERNEL = ROOT / "GENERAL-5.md"

REQUIRED_TOP_LEVEL = {"schema", "status", "purpose", "source", "run_policy", "metrics", "scenarios"}
REQUIRED_SCENARIO = {"id", "category", "rules", "request", "expected_execution", "must", "must_not"}
ALLOWED_CATEGORIES = {
    "core", "research", "hypothesis", "change", "delegation", "review",
    "approval", "governance", "continuity", "recovery", "safety",
    "tooling", "observability",
}
ALLOWED_EXECUTION = {
    "single_agent", "single_agent_limited",
    "bounded_parallel_optional", "independent_reviewer_required",
}
REQUIRED_METRICS = {
    "task_success", "safety_violation_count", "user_correction_count",
    "approval_interruption_count", "elapsed_seconds", "input_tokens",
    "output_tokens", "agent_run_count", "handoff_failure_count",
}
REQUIRED_RUN_POLICY = {
    "minimum_runs_per_candidate_scenario", "randomize_scenario_order",
    "record_exact_candidate", "record_environment",
    "require_trace_or_evidence_locator",
    "do_not_treat_scenario_specification_as_execution_evidence",
}


def fail(errors):
    for error in errors:
        print(error, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    errors = []

    kernel_rules = {int(m) for m in re.findall(r"^(\d+)\. \*\*", KERNEL.read_text(encoding="utf-8"), re.M)}
    if not kernel_rules:
        fail(["Не удалось прочитать номера правил из GENERAL-5.md."])

    data = json.loads(SCENARIOS.read_text(encoding="utf-8"))

    missing = REQUIRED_TOP_LEVEL - set(data)
    if missing:
        errors.append(f"Отсутствуют поля верхнего уровня: {sorted(missing)}")

    missing_metrics = REQUIRED_METRICS - set(data.get("metrics", []))
    if missing_metrics:
        errors.append(f"Отсутствуют обязательные метрики: {sorted(missing_metrics)}")

    missing_policy = REQUIRED_RUN_POLICY - set(data.get("run_policy", {}))
    if missing_policy:
        errors.append(f"Отсутствуют условия прогона: {sorted(missing_policy)}")

    if data.get("run_policy", {}).get("minimum_runs_per_candidate_scenario", 0) < 3:
        errors.append("Минимум прогонов на сценарий должен быть не меньше 3.")

    seen = set()
    covered = set()
    for scenario in data.get("scenarios", []):
        sid = scenario.get("id", "<без id>")
        absent = REQUIRED_SCENARIO - set(scenario)
        if absent:
            errors.append(f"{sid}: отсутствуют поля {sorted(absent)}")
            continue
        if sid in seen:
            errors.append(f"{sid}: повторяющийся id")
        seen.add(sid)
        if scenario["category"] not in ALLOWED_CATEGORIES:
            errors.append(f"{sid}: неизвестная категория {scenario['category']}")
        if scenario["expected_execution"] not in ALLOWED_EXECUTION:
            errors.append(f"{sid}: неизвестный expected_execution {scenario['expected_execution']}")
        if not scenario["rules"]:
            errors.append(f"{sid}: не указано ни одного правила ядра")
        for rule in scenario["rules"]:
            if rule not in kernel_rules:
                errors.append(f"{sid}: правило {rule} отсутствует в ядре")
            covered.add(rule)
        for field in ("must", "must_not"):
            if not scenario[field]:
                errors.append(f"{sid}: пустой список {field}")
        if not scenario["request"].strip():
            errors.append(f"{sid}: пустой запрос")

    uncovered = kernel_rules - covered
    if uncovered:
        errors.append(f"Правила ядра без единого сценария: {sorted(uncovered)}")

    if errors:
        fail(errors)

    print(
        f"Проверено {len(seen)} сценариев; покрыты все {len(kernel_rules)} правил ядра."
    )


if __name__ == "__main__":
    main()
