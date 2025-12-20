FROM flink:1.20.0-scala_2.12-java17

COPY target/scala-2.12/credit-spreads-flink-assembly-0.1.0.jar /opt/flink/job.jar

ENTRYPOINT []
CMD ["flink", "run", "-d", "/opt/flink/job.jar"]

