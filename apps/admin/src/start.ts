import { createStart } from "@tanstack/react-start"

// Payment data and relative times change by the second, so pages render in the browser only.
// The server still renders the document shell and runs the server functions.
export const startInstance = createStart(() => ({ defaultSsr: false }))
