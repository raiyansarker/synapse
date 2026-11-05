package synapse.upi.payment;

/** Response body. {@code atomicId} is the id the publishing bank tracks. */
public record AcceptedPayment(String atomicId) {}
