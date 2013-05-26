name := "montecarlo"

scalaVersion := "2.10.1"

resolvers += "Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"

libraryDependencies += "com.github.axel22" %% "scalameter" % "0.2"

unmanagedBase <<= baseDirectory { base => base / "../../common/scala/lib" }

