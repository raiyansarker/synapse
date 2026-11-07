# upi

Spring Boot service. PostgreSQL and RabbitMQ settings live in `src/main/resources/application.yaml` and are filled from environment variables.

Requires Java 25.

## Environment

Copy the example file and edit it:

```bash
cp .env.example .env
```

`.env` is gitignored. `.env.example` is the committed template.

| Variable | Purpose |
| --- | --- |
| `SPRING_DATASOURCE_URL` | JDBC URL, including the database name |
| `SPRING_DATASOURCE_USERNAME` | Database user |
| `SPRING_DATASOURCE_PASSWORD` | Database password |
| `SPRING_RABBITMQ_ADDRESSES` | RabbitMQ URI (`amqp://` or `amqps://`). Path is the virtual host. |

`application.yaml` references those names directly:

```yaml
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL}
    username: ${SPRING_DATASOURCE_USERNAME}
    password: ${SPRING_DATASOURCE_PASSWORD}
  rabbitmq:
    addresses: ${SPRING_RABBITMQ_ADDRESSES}
```

Hibernate uses `ddl-auto: update`, so the schema is updated from entities on startup. Spring AMQP auto-configures `RabbitTemplate`, `AmqpAdmin`, and `@RabbitListener` support from `spring-boot-starter-amqp`.

### Local Postgres

`.env.example` targets a database named `upi` on localhost:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/upi?sslmode=require
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres
```

Create that database before starting the app. Drop `sslmode=require` if the local server does not use TLS.

### RabbitMQ

`.env.example` targets a local broker:

```
SPRING_RABBITMQ_ADDRESSES=amqp://guest:guest@localhost:5672/
```

CloudAMQP (and similar) give one URI. Put that in `.env` as `SPRING_RABBITMQ_ADDRESSES`. Use `amqps://` for TLS. The path after the host is the virtual host. Connection details alone do not declare exchanges or queues.

### Neon

Put the host and database in the URL. Keep the user and password in their own variables:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://<host>/<database>?sslmode=require&channelBinding=require
SPRING_DATASOURCE_USERNAME=<user>
SPRING_DATASOURCE_PASSWORD=<password>
```

## Run

From this directory:

```bash
./gradlew bootRun
```

`bootRun` reads `.env` and exports each `KEY=VALUE` line into the process. Lines that are empty, comments, or missing `=` are skipped.

The app listens on port 8080. Set `SERVER_PORT` to use another port.

Running from an IDE does not load `.env`. Export the same three variables in the run configuration, or start the app with `./gradlew bootRun`.
