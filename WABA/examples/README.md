# Curated Examples

The example surface is intentionally small. These are the frameworks exercised by the supported docs and tests.

## 1. Classical ABA Smoke

Framework: `examples/aspartix_test/simple_attack.lp`

```bash
./bin/waba run \
  --framework examples/aspartix_test/simple_attack.lp \
  --semantics stable \
  --show projection
```

Expected extension: `{a,c}`.

## 2. Budget-Sensitive Stable Reasoning

Framework: `examples/practical_deliberation/practical_deliberation.lp`

```bash
./bin/waba run \
  --framework examples/practical_deliberation/practical_deliberation.lp \
  --semiring arctic \
  --semantics stable \
  --objective count-min \
  --budget-mode ub \
  --beta 2 \
  --show projection \
  --opt-mode optN
```

This is the supported `count + ub` preset with a rule-based framework.

## 3. Rule-Based Semiring Example

Framework: `examples/scientific_theory/scientific_theory.lp`

```bash
./bin/waba run \
  --framework examples/scientific_theory/scientific_theory.lp \
  --semiring tropical \
  --semantics stable \
  --objective sum-min \
  --budget-mode ub \
  --beta 275 \
  --show projection \
  --opt-mode optN
```

This is the supported `sum + ub` preset on a rule-heavy framework.

## 4. Read-Only Reference Case

Framework: `examples/reference/aspforaba_journal_example.lp`

```bash
./bin/waba run \
  --framework examples/reference/aspforaba_journal_example.lp \
  --semantics preferred \
  --show projection
```

This case is kept to compare the supported classical semantics against the read-only ASPforABA reference suite.
