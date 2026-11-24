# 6amMart API Automation (Karate DSL)

Two kinds of tests live side by side, each with its own runner and report:

| Layer | What it is | Folder | Runner | Report |
|---|---|---|---|---|
| **Endpoint suites** | one feature per Postman sub-folder, stateless, parallel, positive + negative per endpoint | `src/test/resources/common/public/…` | `CommonPublicRunner` | `target/karate-reports/common-public/karate-summary.html` |
| **Business scenarios (E2E)** | multi-actor flows (customer → vendor → admin → delivery man …) that create their own data and delete it again | `src/test/resources/scenarios/…` | `E2ERunner` | `target/karate-reports/e2e/karate-summary.html` |
| **API coverage** | which Postman endpoints were actually hit, split into 2xx / 4xx | generated | after every run | `target/api-coverage/api-coverage.html` |

## Run

```bash
mvn test                                                   # everything (common-public, then e2e)
mvn test -Dtest=CommonPublicRunner                         # endpoint suites only
mvn test -Dtest=E2ERunner                                  # business scenarios only
mvn test -Dtest=E2ERunner -Dkarate.options="--tags @order"            # one business area
mvn test -Dtest=E2ERunner -Dkarate.options="--tags @journey"          # the main order journey
mvn test -Dtest=E2ERunner -Dkarate.options="--tags @negative"         # only negative/edge scenarios
mvn test -Dtest=E2ERunner -Dkarate.options="--tags @known-issue"      # documented server defects (expected to FAIL)
mvn test -Dthreads=5                                       # parallelism (E2E defaults to 1, see "Findings")
mvn test -DbaseUrl=https://other-host                      # another environment
```

Tags: `@e2e` + business area (`@order`), `@journey`, `@positive` / `@negative`, `@security`, `@smoke`,
`@writes` (creates data), `@external` (calls Google), `@known-issue` (real defect, excluded by default),
`@blocked` (waiting for access, excluded by default).

## How a business scenario is built

```
scenarios/order/customer-order-journey.feature      the story, readable top to bottom
        │  calls
steps/customer/*.feature                            one API call each: register, login, search-items, cart-add,
steps/catalog/find-item.feature                     place-order, order-queries, cancel-order, cleanup, sweep …
        │  uses
karate-config.js                                    ctx (cleanup stack), rnd (unique data), expectStatus
```

* **Steps take arguments and return values**; `expect` is the status they assert (success by default, any code or a
  list for negative tests, `'any'` for cleanup). Every step is reusable by every scenario.
* **`ctx.defer(name, feature, args)`** registers a cleanup right after something is created; cleanups run **in reverse**.
  `afterScenario` runs whatever is still pending, **so data is removed even when an assertion fails half-way**
  (proved with a deliberately failing scenario). Scenarios also perform the delete explicitly as a visible
  "delete all data" stage and mark it with `ctx.done(name)`.
* **`steps/customer/sweep.feature`** cancels + deletes *every* order and the cart of a customer/guest — registered in the
  negative suites so an unexpected `201` can never leak records.
* Data is unique per run (`karate.<uid>@example.com`, random phone) and discovered at runtime (`find-item`), never hard-coded.
* Rules for writing steps (learned the hard way): read **only** `__arg` inside a step (a called feature can see the caller's
  variables), and always call as `* def x = call read(…)` — a bare `* call` shares scope and leaks variables both ways.

### Adding the vendor / admin / delivery-man stages
Add `steps/vendor/*.feature`, `steps/admin/*.feature`, `steps/deliveryman/*.feature` in the same style and call them at the
`EXTENSION POINT` comment in `customer-order-journey.feature`. Other flows (refund, reorder, wallet, coupon, rental booking …)
are new files under `scenarios/<area>/` re-using the same steps.

## API coverage report
Put the Postman collection JSON in `postman/` (any `*.json`). After each run `target/api-coverage/api-coverage.html`
lists every endpoint with call counts, 2xx vs 4xx, and a "not covered yet" list per Postman folder — this is the
progress tracker for "cover the full API list".

## Status

| Postman folder | Endpoint suites | Business scenarios |
|---|---|---|
| Common (public) | done - 237 scenarios | - |
| Customer App | order/cart/auth/profile exercised through the order journey (47 scenarios) - dedicated suites next | order journey (customer side) done |
| Vendor App / Delivery Man / ERP / AI / Reels / Rental / RideShare / Service / Tax | pending | pending |

## Access needed to finish the full order flow (create vendor → approve → product → … → delivered)
1. **Admin actions are not API.** The admin panel is a web form (`/login_submit`) protected by an **image captcha**
   (`Captcha Failed` is returned without it). Automation will not solve or bypass a captcha. Disable the admin login
   captcha on the test server, or provide another admin access path, and the `steps/admin/*` (approve vendor / product /
   delivery man, assign delivery man) can be written against the web session.
2. **Vendor self-registration needs an SMS OTP** (`is_sms_active = true`) and a profile image. Either an OTP bypass on
   test, or an existing **approved vendor** login, is required. Existing approved **vendor** and **delivery-man** logins
   alone are enough to automate: vendor confirm → processing → handover, delivery man accept → picked up → delivered.
3. Credentials are never committed: `-DcustomerEmail= -DcustomerPassword= -DadminEmail= -DadminPassword=` or env vars
   `SIXAM_CUSTOMER_EMAIL`, `SIXAM_CUSTOMER_PASSWORD`, `SIXAM_ADMIN_EMAIL`, `SIXAM_ADMIN_PASSWORD`.

## Findings on the test server
Defects (`@known-issue`, fail on purpose, excluded from the default run):
1. `GET /config/place-api-details?placeid=<invalid>` → HTTP 200 with the raw Google error in `content` (should be 4xx).
2. `GET /vehicle/extra_charge?distance=abc` → 200 (no numeric validation; should be 422).
3. `POST /customer/order/place` with `payment_method=wallet` and no balance → **HTTP 201** with the error hidden in `content.errors`.
4. `PUT /customer/order/cancel` on an already cancelled order → 200 again (should be rejected).
5. `POST /customer/cart/add` with a non-existent `store_id` → 201.
6. `DELETE /customer/order/delete` on an already deleted order → 404 on some runs, 200 on others (intermittent).

Observations (not asserted as defects):
* **Parallel orders against one store intermittently fail with `403 "Failed to place order"`** (3 parallel scenarios,
  a different one failed on each run; sequential runs never failed). Hence E2E runs with 1 thread by default.
* A forged/expired bearer token is not answered with 401 on guest-capable endpoints; the caller silently becomes a guest
  (no data is exposed — asserted).
* `404` responses for missing orders carry `errors: []` instead of the usual `errors[0]` object.
* `a@b` is accepted as a newsletter e-mail address (valid per RFC, probably unintended).
* Removing a customer account does not remove that customer's orders; scenarios therefore delete orders explicitly first.

Confirmed good: server-side pricing ignores a forged cart price; delivery charge = delivery total − take-away total;
other customers get 404 for details / track / cancel / delete of someone else's order; stock limit enforced on cart add.

## Side effects on the target server
Scenarios create customers, carts and orders (all removed again) and `@writes` newsletter rows
(`karate.<uuid>@example.com`). Runs from before the cleanup safety net existed may have left a few test orders for
already-deleted customers (ids roughly 102887-102912); remove them from the admin panel if they bother you.
