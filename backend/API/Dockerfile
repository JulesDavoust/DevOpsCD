FROM gradle:8.11.1-jdk23 AS builder
WORKDIR /app
COPY /app/build.gradle settings.gradle /app/
COPY /app/src /app/src
RUN gradle build --no-daemon

FROM eclipse-temurin:23-jre AS runtime
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
