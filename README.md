# vault-cron

A small Foundry project: a per-user vault with a scheduled withdrawal, plus a
scheduler that arms it.

## Layout

```
src/     Vault.sol, Scheduler.sol
test/    Vault.t.sol
```

No submodules. The tests use a minimal inline `Vm` interface instead of
forge-std, so a fresh clone runs with nothing else installed.

## Running

```sh
forge build
forge test
forge fmt --check
```

`forge test` reports **9 passing**.

## Design

`Vault` allows exactly one deposit per address and one withdrawal, released
after a fixed 1-hour delay. `Scheduler` mirrors the deadline locally but the
vault remains the source of truth. No proxy, no governance, no pause.
