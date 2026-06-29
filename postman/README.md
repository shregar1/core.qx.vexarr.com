# QX Broker — HTTP Admin API — Postman collection

Generated from `_inventory.json` by `../../../postman/gen_collection.py`
(central copy at `/Users/shreyansh/Documents/vexarr/postman/`).

## Files

| File | What |
| --- | --- |
| `qx.postman_collection.json` | The collection — every endpoint, one collection for all stages. |
| `qx.<stage>.postman_environment.json` | One environment per stage (below). |

## Stages

Switch the Postman *environment* to switch stage — not the collection.

| Stage | Environment file | `base_url` |
| --- | --- | --- |
| Local / Dev | `qx.local-dev.postman_environment.json` | `http://localhost:9090` |
| Integration | `qx.integration.postman_environment.json` | `https://admin.integration.qx.vexarr.com` |
| Staging | `qx.staging.postman_environment.json` | `https://admin.staging.qx.vexarr.com` |
| Production | `qx.production.postman_environment.json` | `https://admin.qx.vexarr.com` |

> Non-production hostnames follow the `<service>.<env>.qx.vexarr.com`
> convention and may not be literal deploy targets — edit `base_url` per stage.

## Auth

The HTTP surface (/metrics, /api/*, dashboard assets) is fully PUBLIC and unauthenticated — there is no Authorization check in handle_metrics_connection. The broker's bearer-token + keyx validation (admin/owner role, crates/broker/src/auth_keyx.rs) is enforced ONLY on the gRPC data-plane listener (check_auth_combined), not on HTTP. An access_token variable is kept in the collection only in case a reverse proxy is placed in front of the broker to add auth; the broker itself ignores it.

Auth header(s): . Set them (and `base_url`) in the active environment.
`token` / `api_key` style vars are typed **secret** so Postman masks them.

## Examples & tests

Each request ships **≥ 5 saved example responses** (one per status case) and an
elaborate **`test`** script (response-shape asserts, success-payload field
asserts, and variable captures for chaining). A collection-level test runs
baseline assertions on every request.
