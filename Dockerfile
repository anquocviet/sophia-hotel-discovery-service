# -------- Base Image --------
FROM eclipse-temurin:17-jdk-alpine AS base
WORKDIR /app

# Copy Gradle wrapper & configs
COPY ./gradlew gradlew
COPY ./gradle gradle
COPY ./build.gradle settings.gradle ./
RUN chmod +x gradlew

# Cache dependencies
RUN ./gradlew dependencies --no-daemon

# -------- Development Stage --------
FROM base AS dev
EXPOSE 8761
CMD ["./gradlew", "bootRun", "-x compileJava", "--no-daemon"]

# -------- Staging Stage --------
FROM base AS staging
COPY . .
RUN ./gradlew build --no-daemon -x test

FROM eclipse-temurin:17-jdk-alpine AS staging-runtime
WORKDIR /app
COPY --from=staging /app/build/libs/*.jar app.jar
EXPOSE 8761
CMD ["java", "-jar", "app.jar"]

# -------- Production Stage --------
FROM base AS builder
COPY . .
RUN ./gradlew build --no-daemon -x test

FROM eclipse-temurin:17-jdk-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8761
CMD ["java", "-jar", "app.jar"]
