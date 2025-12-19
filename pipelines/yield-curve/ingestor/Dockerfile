FROM eclipse-temurin:17-jre

WORKDIR /app
COPY target/scala-2.13/fred-ingestor-assembly.jar app.jar

CMD ["java", "-jar", "app.jar"]
