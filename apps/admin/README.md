# admin

Admin dashboard for Synapse Bank. [TanStack Start](https://tanstack.com/start) (React), TanStack Router, Query and Table, Tailwind v4, and shadcn/ui components only (copied into `src/components/ui`, no other component library).

Requires Node 22.

## Run

```bash
cd apps/admin
npm install
cp .env.example .env
npm run dev
```

Opens on http://localhost:3000. It starts on sample data, so it needs no backend.

For production: `npm run build`, then `npm start`. The server reads `API_MODE`, `SWITCH_URL` and `PORT` from its environment (`npm start` does not read `.env`).

| Variable | Purpose |
| --- | --- |
| `API_MODE` | `mock` serves sample data from the dashboard's own server, following the real payment state machine. `live` calls the switch. |
| `SWITCH_URL` | Where the dashboard's server finds the switch. Defaults to `http://localhost:8080`. |

## How it fits together

The browser only talks to this app. Every data call is a Start server function (`src/lib/api.ts`) that runs on the dashboard's server and calls the switch from there. That means no CORS headers on the switch, no dev proxy, and `SWITCH_URL` never reaches the browser.

- `src/routes`: file-based TanStack Router routes. `/overview` and `/payments`. `?payment=<id>` opens the payment sheet on any page, and the Payments filters (`q`, `outcome`) are in the URL, so a view can be linked and survives a reload.
- `src/lib/queries.ts`: TanStack Query. The payment list refreshes every 2 seconds.
- `src/routes/payments.tsx`: TanStack Table for sorting, filtering and paging.
- `src/server`: the two backends behind the server functions. `mock.server.ts` and `switch.server.ts`. Neither is included in the browser bundle.
- Pages render in the browser only (`src/start.ts`). The server renders the document shell and runs the server functions.

## Pages

- **Overview**: 24 hour volume, success rate, in-flight count, an hourly chart, and a *Needs attention* list. Attention means `REVERSAL_FAILED` (payer debited, payee not credited, refund failed) or a payment in flight for more than 2 minutes.
- **Payments**: searchable, filterable, sortable ledger. Click a row for the path it took through the switch.
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

The field names match the `Ledger` entity, so it is a repository call plus a DTO. Until it exists, use `mock` mode.
