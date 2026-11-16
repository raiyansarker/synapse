# admin

Operator dashboard for Synapse Bank. React, Vite, Tailwind, and shadcn/ui components only (copied into `src/components/ui`, no other component library).

Requires Node 20+.

## Run

```bash
cd apps/admin
npm install
cp .env.example .env
npm run dev
```

Opens on http://localhost:5173.

| Variable | Purpose |
| --- | --- |
| `VITE_API_MODE` | `mock` runs against in-browser sample data that follows the real payment state machine. `live` talks to the switch. |
| `VITE_SWITCH_URL` | Where the dev server proxies `/api`. Defaults to `http://localhost:8080`. The switch sends no CORS headers, so the browser never calls it directly. |

## Pages

- **Overview**: 24 hour volume, success rate, in-flight count, an hourly chart, and a *Needs attention* list. Attention means `REVERSAL_FAILED` (payer debited, payee not credited, refund failed) or a payment in flight for more than 2 minutes.
- **Payments**: searchable, filterable ledger. Click a row for the path it took through the switch.
- **New payment** (header): sends a payment to the switch.
- **Theme**: light or dark from the header. The first visit follows your system setting; after that the choice is saved in the browser.

## What the switch has today, and what it still needs

The switch (`apps/upi`) exposes two routes. Live mode uses them as they are:

| Route | Used for |
| --- | --- |
| `POST /api/pay` | New payment |
| `GET /api/pay/{id}` | "Check state on the switch" in the payment sheet |

The payment list needs a route that does not exist yet. Live mode calls it, wrapped in the shared `{ success, data, meta }` envelope:

| Route | Returns |
| --- | --- |
| `GET /api/admin/payments` | `Ledger[]`: `id, sva, rva, amount, state, createdAt, updatedAt` |

The field names match the `Ledger` entity, so it is a repository call plus a DTO. Until they exist, use `mock` mode.
