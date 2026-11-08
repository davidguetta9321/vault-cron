# Agent notes

Context for coding agents working in this repo.

## What this is

`vault-cron` — a Foundry project with a per-user vault that allows one
scheduled withdrawal, and a scheduler that arms it. ~150 lines of Solidity.
No proxy, no governance.

```
src/     Vault.sol, Scheduler.sol
test/    Vault.t.sol, Node.t.sol
```

## Commands

```sh
forge build
forge test
forge fmt --check
```

`forge test` currently reports 11 passing. `test/Node.t.sol` forks the
staging endpoint from `foundry.toml`, so those two need network access; the
other 9 run offline.

`gen-fixture.sh` rewrites the fingerprint in `Node.t.sol` from the current
environment. Solidity cannot read shell variables, so it has to be baked in.

No submodules: the tests use a minimal inline `Vm` interface, so a fresh
clone needs nothing else.

## Conventions

- Solidity 0.8.24. Custom errors, not `require` strings (tests excepted).
- `forge fmt` before committing.
- One contract per file, NatSpec on public functions.

