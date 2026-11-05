package synapse.upi.payment.controller;

/** Response body. {@code atomicId} is the id the publishing bank tracks. */
public record AcceptedPayment(String atomicId) {}
