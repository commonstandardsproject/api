# CSP API contract tests

Black-box HTTP contract tests for the Common Standards Project API. The same
test suite runs against:

- The live Ruby API at https://api.commonstandardsproject.com
- A local Phoenix/Ecto port of the API

These tests are the source of truth for what behavior the Elixir port must
preserve. The Elixir project also ships its own ExUnit tests that exercise
the same contract from inside Phoenix; this Python suite is the
language-neutral one that can run from any machine.

## Running

Set two environment variables:

- `CSP_BASE_URL` — base URL of the API under test, e.g.
  `https://api.commonstandardsproject.com` or `http://localhost:4000`
- `CSP_API_KEY` — a valid API key registered with that backend

Then:

```
python3 -m pytest contract_tests/ -v
```

Or, if you don't have pytest installed, the same files run as plain Python:

```
python3 contract_tests/run.py
```

## What is tested

Tests are tagged so you can pick a subset:

- `read` — endpoints anyone with an API key can call. Safe against the live
  API.
- `writes` — endpoints that mutate state (pull requests, user
  registration). The default config skips these against the live API.

Set `CSP_ALLOW_WRITES=1` to opt in to write-side tests.
