FROM flink:1.20.0-scala_2.12-java17

COPY target/scala-2.13/yield-curve-flink-assembly.jar /opt/flink/job.jar

CMD ["flink", "run", "-d", "/opt/flink/job.jar"]
