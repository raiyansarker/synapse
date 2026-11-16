import { ApiError, type Api } from "./api"
import type { NewPayment, Payment, PaymentState } from "./types"

// Same rules as synapse.common.VirtualAddress.
const VA = /^[a-z0-9]+@[a-z]+$/
const STEP_MS = 1500 // upi.mock.delay

function rng(seed: number) {
  return () => {
    seed |= 0; seed = (seed + 0x6d2b79f5) | 0
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
const rand = rng(20261105)
const pick = <T,>(xs: T[]) => xs[Math.floor(rand() * xs.length)]
const hex = (n: number) => Array.from({ length: n }, () => Math.floor(rand() * 16).toString(16)).join("")
const uuid = () => `${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}`

type Route = PaymentState[]
const P = {
  completed: ["ACCEPTED", "DEBIT_AUTHORIZATION_PENDING", "DEBIT_AUTHORIZED", "CREDIT_AUTHORIZATION_PENDING", "CREDIT_AUTHORIZED", "ACKNOWLEDGING", "COMPLETED"] as Route,
  debitDeclined: ["ACCEPTED", "DEBIT_AUTHORIZATION_PENDING", "DEBIT_DECLINED"] as Route,
  debitFailed: ["ACCEPTED", "DEBIT_AUTHORIZATION_PENDING", "DEBIT_AUTHORIZATION_FAILED"] as Route,
  reversed: ["ACCEPTED", "DEBIT_AUTHORIZATION_PENDING", "DEBIT_AUTHORIZED", "CREDIT_AUTHORIZATION_PENDING", "REVERSAL_PENDING", "REVERSED"] as Route,
  reversalFailed: ["ACCEPTED", "DEBIT_AUTHORIZATION_PENDING", "DEBIT_AUTHORIZED", "CREDIT_AUTHORIZATION_PENDING", "REVERSAL_PENDING", "REVERSAL_FAILED"] as Route,
}
function route(): Route {
  const r = rand()
  return r < 0.82 ? P.completed : r < 0.88 ? P.debitDeclined : r < 0.91 ? P.debitFailed : r < 0.985 ? P.reversed : P.reversalFailed
}

const NAMES = ["raiyan", "nadia", "tanvir", "sabrina", "imran", "farhana", "rafi", "mitu", "arif", "sumaiya", "kabir", "lamia", "shuvo", "tania"]
const iso = (ms: number) => new Date(ms).toISOString()
const now = Date.now()

// Bank handles the sample switch recognises.
const HANDLES = ["city", "ucb", "brac"]

function va() { return `${pick(NAMES)}${rand() < 0.3 ? Math.floor(rand() * 90 + 10) : ""}@${pick(HANDLES)}` }
function amount() { return Math.round((rand() < 0.85 ? rand() ** 2.2 * 12000 : rand() * 180000) * 100) / 100 + 10 }

const payments: Payment[] = []
for (let i = 0; i < 160; i++) {
  const created = now - Math.floor(rand() * 24 * 36e5) - 20 * 60e3
  const r = route()
  const sva = va(); let rva = va(); if (rva === sva) rva = `${pick(NAMES)}@${pick(HANDLES)}`
  payments.push({ id: uuid(), sva, rva, amount: amount(), state: r[r.length - 1], createdAt: iso(created), updatedAt: iso(created + r.length * STEP_MS) })
}
// Two the operator should notice: one stuck mid-flight, one that lost money.
payments.push({ id: uuid(), sva: "tanvir@ucb", rva: "nadia@brac", amount: 4200, state: "CREDIT_AUTHORIZATION_PENDING", createdAt: iso(now - 41 * 60e3), updatedAt: iso(now - 38 * 60e3) })
payments.push({ id: uuid(), sva: "mitu@city", rva: "arif@ucb", amount: 15750, state: "REVERSAL_FAILED", createdAt: iso(now - 3 * 36e5), updatedAt: iso(now - 3 * 36e5 + 40e3) })

function advance(p: Payment, r: Route, i = 1) {
  if (i >= r.length) return
  setTimeout(() => { p.state = r[i]; p.updatedAt = iso(Date.now()); advance(p, r, i + 1) }, STEP_MS)
}

const wait = <T,>(v: T) => new Promise<T>((res) => setTimeout(() => res(structuredClone(v)), 120))
const fail = (title: string, detail: string, status: number): never => { throw new ApiError(title, detail, status, uuid()) }

export const mockApi: Api = {
  listPayments: () => wait([...payments].sort((a, b) => b.createdAt.localeCompare(a.createdAt))),
  async getPaymentState(id) {
    const p = payments.find((x) => x.id === id)
    return p ? wait(p.state) : fail("Transaction not found", `No Transaction exists with the given id ${id}`, 404)
  },
  async createPayment(req: NewPayment) {
    if (!VA.test(req.sva) || !VA.test(req.rva)) fail("Validation failed", "Virtual address must look like name@bank.", 400)
    if (!(req.amount >= 0.01 && req.amount <= 1_000_000)) fail("Validation failed", "Amount must be between 0.01 and 1,000,000.00.", 400)
    if (![req.sva, req.rva].every((a) => HANDLES.includes(a.split("@")[1]))) fail("Bank not found", "One or both virtual-address banks are unknown.", 404)
    const t = iso(Date.now())
    const p: Payment = { id: uuid(), sva: req.sva, rva: req.rva, amount: req.amount, state: "ACCEPTED", createdAt: t, updatedAt: t }
    payments.push(p)
    advance(p, route())
    return wait(p.id)
  },
}
