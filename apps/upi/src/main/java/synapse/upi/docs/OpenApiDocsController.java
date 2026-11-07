package synapse.upi.docs;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class OpenApiDocsController {
  @GetMapping(value = "/docs", produces = MediaType.TEXT_HTML_VALUE)
  public String docs() {
    return """
        <!doctype html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
            <title>UPI API</title>
            <script src="https://unpkg.com/@stoplight/elements@8.5.2/web-components.min.js"></script>
            <link rel="stylesheet" href="https://unpkg.com/@stoplight/elements@8.5.2/styles.min.css" />
            <style>
              html, body { margin: 0; height: 100%; }
              elements-api { display: block; height: 100vh; }
            </style>
          </head>
          <body>
            <elements-api
              apiDescriptionUrl="/v3/api-docs"
              router="hash"
              layout="sidebar"
            ></elements-api>
          </body>
        </html>
        """;
  }
}
