name := "yield-curve-flink"
version := "0.1.0"
scalaVersion := "2.12.18"

libraryDependencies ++= Seq(
  "org.apache.flink" %% "flink-streaming-scala" % "1.20.0" % "provided",
  "org.apache.flink" % "flink-clients" % "1.20.0" % "provided",
  "org.apache.flink" % "flink-connector-kafka" % "3.4.0-1.20",
  "com.lihaoyi" %% "ujson" % "3.1.0"
)

assembly / assemblyMergeStrategy := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case x => MergeStrategy.first
}
