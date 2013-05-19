name := "geneticalgorithm"

scalaVersion := "2.10.1"

libraryDependencies ++= Seq(
	"org.scala-lang" % "scala-reflect" % "2.10.1"
)

unmanagedBase <<= baseDirectory { base => base / "../../common/scala/lib" }

