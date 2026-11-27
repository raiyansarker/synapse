package synapse.bank.docs;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.PathItem;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.ArraySchema;
import io.swagger.v3.oas.models.media.BooleanSchema;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.DateTimeSchema;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.media.ObjectSchema;
import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import java.util.List;
import java.util.Map;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

  @Bean
  OpenAPI openAPI() {
    return new OpenAPI()
        .info(new Info().title("Bank").description("Synapse bank API").version("0.0.1"))
        .components(
            new Components()
                .addSecuritySchemes(
                    "basicAuth", new SecurityScheme().type(SecurityScheme.Type.HTTP).scheme("basic")))
        .addSecurityItem(new SecurityRequirement().addList("basicAuth"));
  }

  @Bean
  OpenApiCustomizer apiEnvelopeCustomizer() {
    return openApi -> {
      Components components = openApi.getComponents();
      if (components == null) {
        components = new Components();
        openApi.setComponents(components);
      }
      components.addSchemas(
          "ApiError",
          new ObjectSchema()
              .addProperties("title", new StringSchema())
              .addProperties("detail", new StringSchema())
              .addProperties(
                  "reasons",
                  new ArraySchema()
                      .items(new ObjectSchema().additionalProperties(new StringSchema()))));
      components.addSchemas(
          "ApiMeta",
          new ObjectSchema()
              .addProperties("requestId", new StringSchema())
              .addProperties("timestamp", new DateTimeSchema()));
      Schema<?> metaRef = new Schema<>().$ref("#/components/schemas/ApiMeta");
      Schema<?> errorRef = new Schema<>().$ref("#/components/schemas/ApiError");

      for (Map.Entry<String, PathItem> path : openApi.getPaths().entrySet()) {
        for (Map.Entry<PathItem.HttpMethod, Operation> op : path.getValue().readOperationsMap().entrySet()) {
          Operation operation = op.getValue();
          boolean open =
              (path.getKey().equals("/api/users") && op.getKey() == PathItem.HttpMethod.POST)
                  || path.getKey().equals("/docs");
          if (open) {
            operation.setSecurity(List.of());
          }
          if (operation.getResponses() == null) {
            operation.setResponses(new io.swagger.v3.oas.models.responses.ApiResponses());
          }
          if (!open && !operation.getResponses().containsKey("403")) {
            operation.getResponses().addApiResponse("403", errorResponse("Forbidden", errorRef, metaRef));
          }
          if (operation.getRequestBody() != null && !operation.getResponses().containsKey("400")) {
            operation.getResponses().addApiResponse("400", errorResponse("Bad Request", errorRef, metaRef));
          }
          for (Map.Entry<String, io.swagger.v3.oas.models.responses.ApiResponse> entry :
              operation.getResponses().entrySet()) {
            Content content = entry.getValue().getContent();
            if (content == null) {
              continue;
            }
            for (Map.Entry<String, MediaType> media : content.entrySet()) {
              boolean json =
                  media.getKey().equals(org.springframework.http.MediaType.APPLICATION_JSON_VALUE)
                      || media.getKey().equals("*/*");
              Schema<?> original = media.getValue().getSchema();
              if (!json || original == null || "string".equals(original.getType())) {
                continue;
              }
              Schema<?> wrapped = new Schema<>().type("object");
              if (entry.getKey().startsWith("2")) {
                wrapped.addProperties("success", new BooleanSchema().example(true));
                wrapped.addProperties("data", original);
              } else {
                wrapped.addProperties("success", new BooleanSchema().example(false));
                wrapped.addProperties("error", errorRef);
              }
              wrapped.addProperties("meta", metaRef);
              media.getValue().setSchema(wrapped);
            }
          }
        }
      }
    };
  }

  private static io.swagger.v3.oas.models.responses.ApiResponse errorResponse(
      String description, Schema<?> errorRef, Schema<?> metaRef) {
    Schema<?> body = new ObjectSchema();
    body.addProperties("success", new BooleanSchema().example(false));
    body.addProperties("error", errorRef);
    body.addProperties("meta", metaRef);
    return new io.swagger.v3.oas.models.responses.ApiResponse()
        .description(description)
        .content(
            new Content()
                .addMediaType(
                    org.springframework.http.MediaType.APPLICATION_JSON_VALUE,
                    new MediaType().schema(body)));
  }
}
