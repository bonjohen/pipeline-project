FROM eclipse-temurin:17-jre

WORKDIR /app
COPY target/scala-2.13/repo-stress-ingestor-assembly-0.1.0.jar app.jar

CMD ["java", "-jar", "app.jar"]

