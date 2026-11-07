package synapse.upi.pay.controller;

import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import synapse.upi.pay.dto.AcceptPayRequest;
import synapse.upi.pay.dto.AcceptPayResponse;

@RestController
@RequestMapping("/api/pay")
public class pay {

  @PostMapping
  public AcceptPayResponse acceptPay(
      @Valid
      @RequestBody
      AcceptPayRequest request
  ) {
    System.out.println(request);
    return new AcceptPayResponse("dsuhfuisdhfui");
  }

  @GetMapping("{id}")
  public void getPayStatus(@PathVariable String id) {
    throw new UnsupportedOperationException("not implemented");
  }
}
