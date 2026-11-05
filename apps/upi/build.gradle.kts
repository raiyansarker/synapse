plugins {
    java
    id("org.springframework.boot") version "4.1.2"
    id("io.spring.dependency-management") version "1.1.7"
}

group = "synapse"
version = "0.0.1-SNAPSHOT"
description = "upi"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("synapse:common:0.0.1-SNAPSHOT")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-restclient")
    implementation("org.springframework.boot:spring-boot-starter-webmvc")
    implementation("org.springframework.statemachine:spring-statemachine-core:4.0.2")
    implementation("dev.dbos:transact-spring-boot-starter:1.2.0")
    implementation("org.springframework.boot:spring-boot-starter-aspectj")
    compileOnly("org.projectlombok:lombok")
    runtimeOnly("org.postgresql:postgresql")
    annotationProcessor("org.projectlombok:lombok")
    testImplementation("org.springframework.boot:spring-boot-starter-data-jpa-test")
    testImplementation("org.springframework.boot:spring-boot-starter-restclient-test")
    testImplementation("org.springframework.boot:spring-boot-starter-webmvc-test")
    testCompileOnly("org.projectlombok:lombok")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    testAnnotationProcessor("org.projectlombok:lombok")
}

tasks.withType<Test> {
    useJUnitPlatform()
    maxParallelForks = 1
}

tasks.named<org.springframework.boot.gradle.tasks.run.BootRun>("bootRun") {
    val envFile = rootProject.file(".env")
    if (envFile.exists()) {
        envFile.readLines()
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("#") && it.contains("=") }
            .forEach { line ->
                val index = line.indexOf('=')
                environment(line.substring(0, index), line.substring(index + 1))
            }
    }
}
