# Build app using Gradle
FROM gradle:8.0.2-jdk19 AS app-build
WORKDIR /app
COPY settings.gradle build.gradle ./
# Found this was the only way to copy in the src directory for some reason.
RUN mkdir src
COPY src ./src
RUN gradle build


# Copy app in from builder into image for production
FROM eclipse-temurin:19.0.2_7-jdk
COPY --from=app-build /app/build/libs/apache-openwhisk-runtime-java-19-1.0.0-all.jar /
ENTRYPOINT [ "java", "-jar", "/apache-openwhisk-runtime-java-19-1.0.0-all.jar" ]
