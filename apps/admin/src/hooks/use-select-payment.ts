import { useNavigate } from "@tanstack/react-router"

/** Opens or closes the payment sheet by setting ?payment= on the current route. */
export function useSelectPayment() {
  const navigate = useNavigate()
  return (id?: string) => navigate({ to: ".", search: (prev: Record<string, unknown>) => ({ ...prev, payment: id }) } as never)
}
