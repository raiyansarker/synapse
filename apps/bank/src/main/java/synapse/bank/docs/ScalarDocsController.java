package synapse.bank.docs;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ScalarDocsController {
  @GetMapping(value = "/docs", produces = MediaType.TEXT_HTML_VALUE)
  public String docs() {
    return """
        <!doctype html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>Bank API</title>
            <style>
              body { margin: 0; }
            </style>
          </head>
          <body>
            <script
              id="api-reference"
              data-url="/v3/api-docs"
              data-configuration='{"theme":"halloween"}'
              src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"
            ></script>
          </body>
        </html>
        """;
  }
}
