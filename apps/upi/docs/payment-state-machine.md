# Payment state machine

The UPI service is the switch. A bank publishes a payment, the switch returns an atomic id, and every later step is a transition on that payment. This file is the handoff for that lifecycle.

## Library

Transitions are defined and enforced by [Spring Statemachine](https://docs.spring.io/spring-statemachine/docs/4.0.2/reference/index.html) `4.0.2`.

| Piece | Role |
| --- | --- |
| `spring-statemachine-core` | The dependency in `build.gradle.kts`. This is the module to keep. |
| `PaymentStateMachineConfig` | `@EnableStateMachineFactory` configuration. States, end states, and external transitions live here. |
| `PaymentStateMachine` | Builds one machine from `StateMachineFactory` per call, restores the payment's current state, sends one event, and returns the next state. |
| `Payment` | The payment the switch tracks. `atomicId` is the id returned to the publishing bank. |

`spring-statemachine-starter` and the JPA, Redis, and Mongo persistence modules are built for Spring Boot 3.5. This service is Spring Boot 4.1, and the Statemachine project has no Boot 4 support. Leave those modules out. When a payment is stored, store it as a normal JPA entity. The state machine is the transition engine, not the database.

A denied event throws `IllegalPaymentTransitionException`. Spring Statemachine reports that as `StateMachineEventResult.ResultType.DENIED`.

## What the switch does

1. A bank publishes a payment. The switch accepts it, mints an atomic id, and returns that id. The payment is `ACCEPTED`.
2. The switch resolves the virtual addresses (`name@bank`, for example `raiyan@city`). The part after `@` is the bank handle. Resolution happens before any money moves. If a handle cannot be resolved, the payment ends as `RESOLUTION_FAILED`.
3. The switch asks the payer's bank to authorize a debit. Balance, limits, and whether the payment may proceed are decided by that bank. On approval the payment is `AUTHORIZED` and the payer has been debited. On refusal it ends as `DECLINED`.
4. The switch sends a credit request to the payee's bank. The payment is `CREDIT_PENDING` while that bank has not answered.
5. If the payee's bank credits the payee, the payment is financially successful (`NOTIFYING`). The switch then sends the result to the payer's bank and the payee's bank. After both have been sent, the payment is `COMPLETED`.
6. If the payee's bank rejects the credit, the payer has already been debited. The switch asks the payer's bank to reverse that debit (`REVERSAL_PENDING`). A successful reversal ends as `REVERSED`. A failed reversal ends as `REVERSAL_FAILED`: the payer is still debited and the payee was not credited.

The publishing bank and the payer's bank may be the same institution. Authorization is still its own step. The debit decision happens when the payer's bank answers, not when the payment is published.

## States

There are 11 states. Five of them are terminal, configured as Spring Statemachine end states.

| State | Waiting on | Money | Terminal |
| --- | --- | --- | --- |
| `ACCEPTED` | The switch, to resolve the virtual addresses | None | No |
| `AUTHORIZATION_PENDING` | The payer's bank | None | No |
| `AUTHORIZED` | The switch, to send the credit | Payer debited | No |
| `CREDIT_PENDING` | The payee's bank | Payer debited | No |
| `NOTIFYING` | The switch, to tell both banks | Settled | No |
| `COMPLETED` | Nobody | Settled | Yes |
| `RESOLUTION_FAILED` | Nobody | None | Yes |
| `DECLINED` | Nobody | None | Yes |
| `REVERSAL_PENDING` | The payer's bank | Payer debited, payee not credited | No |
| `REVERSED` | Nobody | Debit undone | Yes |
| `REVERSAL_FAILED` | Nobody | Payer still debited, payee not credited | Yes |

`AUTHORIZED` and `CREDIT_PENDING` are separate so a retry does not send a second credit. `AUTHORIZED` means the debit is done and the credit has not been sent. `CREDIT_PENDING` means the payee's bank has been asked and has not answered.

`NOTIFYING` and `COMPLETED` are separate so a crash while telling the banks does not look like the credit is still in flight. Stay in `NOTIFYING` until both banks have been sent the success result, then apply `PARTIES_ADVISED`. A failed send is retried in place. It is not a new state, and it does not reverse the credit.

## Transitions

There are 10 external transitions. Anything not in this table is denied.

| From | Event | To | What happened before the event is applied |
| --- | --- | --- | --- |
| `ACCEPTED` | `VPA_RESOLVED` | `AUTHORIZATION_PENDING` | Both virtual addresses resolved, and the debit authorization was sent to the payer's bank |
| `ACCEPTED` | `VPA_UNRESOLVED` | `RESOLUTION_FAILED` | A virtual address could not be resolved. No bank was asked to move money |
| `AUTHORIZATION_PENDING` | `DEBIT_APPROVED` | `AUTHORIZED` | The payer's bank approved the debit |
| `AUTHORIZATION_PENDING` | `DEBIT_DECLINED` | `DECLINED` | The payer's bank refused. It did not debit |
| `AUTHORIZED` | `CREDIT_REQUESTED` | `CREDIT_PENDING` | The credit request was sent to the payee's bank |
| `CREDIT_PENDING` | `CREDIT_APPROVED` | `NOTIFYING` | The payee's bank credited the payee |
| `CREDIT_PENDING` | `CREDIT_REJECTED` | `REVERSAL_PENDING` | The payee's bank rejected the credit. A reversal is now required |
| `NOTIFYING` | `PARTIES_ADVISED` | `COMPLETED` | The success result was sent to both the payer's bank and the payee's bank |
| `REVERSAL_PENDING` | `REVERSAL_APPROVED` | `REVERSED` | The payer's bank reversed the debit |
| `REVERSAL_PENDING` | `REVERSAL_REJECTED` | `REVERSAL_FAILED` | The payer's bank did not reverse the debit |

```mermaid
stateDiagram-v2
  [*] --> ACCEPTED: bank publishes, switch returns atomic id
  ACCEPTED --> AUTHORIZATION_PENDING: VPA_RESOLVED
  ACCEPTED --> RESOLUTION_FAILED: VPA_UNRESOLVED
  AUTHORIZATION_PENDING --> AUTHORIZED: DEBIT_APPROVED
  AUTHORIZATION_PENDING --> DECLINED: DEBIT_DECLINED
  AUTHORIZED --> CREDIT_PENDING: CREDIT_REQUESTED
  CREDIT_PENDING --> NOTIFYING: CREDIT_APPROVED
  CREDIT_PENDING --> REVERSAL_PENDING: CREDIT_REJECTED
  NOTIFYING --> COMPLETED: PARTIES_ADVISED
  REVERSAL_PENDING --> REVERSED: REVERSAL_APPROVED
  REVERSAL_PENDING --> REVERSAL_FAILED: REVERSAL_REJECTED
```

Apply an event only after the step it names has happened. If sending a request to a bank fails, leave the payment in the previous state and retry the send. Enter `AUTHORIZATION_PENDING` only after the payer's bank was asked. Enter `CREDIT_PENDING` only after the payee's bank was asked.

`REVERSAL_PENDING` means a reversal is required. Send it if it has not been sent. The payer bank's answer is the only way out. A repeated reversal request for the same atomic id must be safe.

On `DECLINED`, `RESOLUTION_FAILED`, and `REVERSED`, tell the publishing bank the payment failed. That advice is retried without a further transition. `REVERSAL_FAILED` is terminal inside this machine. Do not add an automatic loop back to `REVERSAL_PENDING`.

## Rules for the next change

- Keep new transitions in `PaymentStateMachineConfig`. The enum `terminal()` flag and the `.end(...)` states stay in agreement.
- Leave balance, limit, and risk checks on the payer's bank.
- Resolve virtual addresses before asking for a debit. Credit only after `DEBIT_APPROVED`.
- One atomic id per payment, minted in `Payment.accept`. Callers treat it as an opaque token.
- A virtual address is `name@bank`: one `@`, with text on both sides.
- Do not add a state per notified bank. Track delivery beside the payment and stay in `NOTIFYING` until both sends have succeeded.
- Timeouts are not states. Map one onto `DEBIT_DECLINED` or `CREDIT_REJECTED` only once the bank outcome is known.
- `PaymentStateMachine` restores state onto a fresh machine for each call. Do not cache one running machine and reuse it across payments.

## Durable execution

DBOS runs in this process. It does not need its own database. With `dbos.datasource.url` unset, it uses `spring.datasource` and creates its tables in the `dbos` schema.

`dbos.datasource.use-listen-notify` is false because the Neon pooler does not deliver `LISTEN`/`NOTIFY`. DBOS polls for bank replies. A direct connection to Postgres can turn that flag back on.

`PaymentWorkflow.start` mints the atomic id and starts one workflow with that id. These steps are checkpointed, so a restart does not repeat a finished one:

| Step | Then the workflow applies |
| --- | --- |
| `resolve` | `VPA_RESOLVED`, or `VPA_UNRESOLVED` when it returns false |
| wait for a debit reply | `DEBIT_APPROVED` or `DEBIT_DECLINED` |
| `requestCredit` | `CREDIT_REQUESTED` |
| wait for a credit reply | `CREDIT_APPROVED` or `CREDIT_REJECTED` |
| `advise` for the payer, then the payee | `PARTIES_ADVISED` |
| `requestReversal` | the reversal reply, `REVERSAL_APPROVED` or `REVERSAL_REJECTED` |

A bank reply enters through `PaymentWorkflow.signal`. `PaymentSignal` chooses the topic. The workflow applies that event with `PaymentStateMachine`. Calls inside the workflow go through the Spring proxy (`self`), because a direct `this` call skips the DBOS checkpoint.

The step bodies do not call the banks yet. The directory, the debit, the credit, the reversal, and the two advice calls replace those bodies. The `@Step` boundary stays.

## Not built yet

No HTTP API, no payment table, no virtual-address directory, and no client that calls the payer or payee bank.
