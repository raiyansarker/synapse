plugins {
    java
    id("io.spring.dependency-management") version "1.1.7"
}

group = "synapse"
version = "0.0.1-SNAPSHOT"
description = "Shared HTTP types for Synapse services"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

repositories {
    mavenCentral()
}

dependencyManagement {
    imports {
        mavenBom("org.springframework.boot:spring-boot-dependencies:4.1.2")
    }
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-webmvc")
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")
}
