# Build app using Gradle
FROM gradle:7.5.1-jdk18 AS app-build
WORKDIR /app
COPY settings.gradle build.gradle ./
# Found this was the only way to copy in the src directory for some reason.
RUN mkdir src
COPY src ./src
RUN gradle build


# Copy app in from builder into image for production
# Note that despite Java 18 being used to invoke Gradle to do the build, the
# built JAR will contain class files for Java 19 because of the Gradle
# toolchain defined. Java 19 here controls the runtime JVM used for users'
# OpenWhisk actions.
FROM eclipse-temurin:19
COPY --from=app-build /app/build/libs/apache-openwhisk-runtime-java-19-1.0.0-all.jar /
ENTRYPOINT [ "java", "-jar", "/apache-openwhisk-runtime-java-19-1.0.0-all.jar" ]
