# ---------- build stage ----------
FROM eclipse-temurin:25-jdk AS build
WORKDIR /app

# Download dependencies first (cached unless pom.xml changes)
COPY mvnw pom.xml ./
COPY .mvn .mvn
# sed strips Windows line endings (CRLF) so mvnw runs on Linux
RUN sed -i 's/\r$//' mvnw && chmod +x mvnw && ./mvnw -B -q dependency:go-offline

# Build the jar
COPY src src
RUN ./mvnw -B -q package -DskipTests

# ---------- run stage ----------
FROM eclipse-temurin:25-jre
WORKDIR /app
RUN useradd --system --create-home spring
USER spring
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]