import { queryOptions } from "@tanstack/react-query"
import { getMode, listPayments } from "./api"

export const paymentsQuery = queryOptions({
  queryKey: ["payments"],
  queryFn: () => listPayments(),
  refetchInterval: 2000, // payments move through the state machine every ~1.5s
  staleTime: 1000,
})

export const modeQuery = queryOptions({ queryKey: ["mode"], queryFn: () => getMode(), staleTime: Infinity })
