# upi

Spring Boot service. PostgreSQL settings live in `src/main/resources/application.yaml` and are filled from environment variables.

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

`application.yaml` references those names directly:

```yaml
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL}
    username: ${SPRING_DATASOURCE_USERNAME}
    password: ${SPRING_DATASOURCE_PASSWORD}
```

Hibernate uses `ddl-auto: update`, so the schema is updated from entities on startup.

### Local Postgres

`.env.example` targets a database named `upi` on localhost:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/upi?sslmode=require
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres
```

Create that database before starting the app. Drop `sslmode=require` if the local server does not use TLS.

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

## Payment flow

A bank publishes a payment with `POST /api/payments`. The body is `sva` (sender virtual address), `amount`, and `rva` (receiver virtual address). `amount` is a `BigDecimal`. The atomic id comes back in `data.atomicId`.

The switch tracks each payment with Spring Statemachine. DBOS runs the steps and waits for the banks. It stores its checkpoints in the `dbos` schema of the same Postgres database. States, transitions, and the workflow are in [docs/payment-state-machine.md](docs/payment-state-machine.md).
