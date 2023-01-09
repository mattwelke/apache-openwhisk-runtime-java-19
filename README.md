# apache-openwhisk-runtime-java-19

A Java 19 runtime or Apache OpenWhisk. Derived from https://github.com/mattwelke/apache-openwhisk-runtime-java-18. The Java 18 version this is derived from has been used in production in a hobby project long enough to be considered production ready. Therefore, this can probably also be considered production ready.

Uses the default heap size and GC configuration for Eclipse Temurin Java 19.

Contains some changes compared to the Java runtimes in the Apache OpenWhisk project:

* **API**: Uses `Map<String, Object>` instead of `com.google.gson.JsonObject` for the function parameter types.
* **Inheritance pattern**: Uses a pattern where the function is a class that extends `com.mattwelke.owr.java.Action` and provides an implementation of the `invoke` method.
* **Included dependencies**: Includes some Maven dependencencies so that the function doesn't need to include them in what's deployed.

## Maven vs. Gradle

The instructions in this README are for Gradle users. Maven instructions are not provided.

## Setting up a project for your function

To set up a project for a function, set up a Java project using the standard Maven layout using `gradle init`. Follow the steps to set up your project as a library (not as an application). This is because you'll be deploying a JAR that contains your class for your function (alongside any dependencies it needs that are not provided by the runtime), and your class will by dynamically loaded from the JAR by the runtime when it needs to. You won't be deploying an executable JAR.

Copy the file `src/main/java/com/mattwelke/owr/java/Action.java` from this code base into your project so that it sets alongside your source code and is included in what is compiled. For example, if you choose the package name `com.myfunc` for your function code, and you choose the class name `MyFunction`, the `src` directory in your directory layout would look like this:

```
└── src
    └── main
        └── java
            └── com
                ├── mattwelke
                │   └── owr
                │       ├── java
                │       │   └── Action.java
                └── myfunc
                    └── MyFunction.java
```

*Note: In the future, this step may not be required because the `Action` class may be hosted as an open source Maven dependency.*

Add the [Gradle Shadow](https://imperceptiblethoughts.com/shadow/) plugin by adding it to your `build.gradle` file. For example:

```gradle
plugins {
    id 'com.github.johnrengelman.shadow' version '7.1.2'
    id 'java-library'
}
...
```

When this plugin is added this way, the result of running `./gradlew build` will automatically change to include an uber JAR, which will be the artifact deployed to OpenWhisk to use this runtime.

## Creating your function

Create a class that extends `Action` and implements the `invoke` method to be the class for your function. You can call it anything you like.

This example demonstrates using the invoke input, using data from the cluster context (which replaces the OpenWhisk per-invoke environment variables in the Java 8 runtime), and setting output.

```java
package com.myfunc;

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

import com.mattwelke.owr.java.Action;

public class MyAction extends Action {

    private static final Logger LOG = Logger.getAnonymousLogger();

    @Override
    public Map<String, Object> invoke(Map<String, Object> input) {
        LOG.info("Input: " + input);
        LOG.info("Context: " + this.clusterContext);

        var output = new HashMap<String, Object>();

        output.put("input", input);
        output.put("context", this.clusterContext);

        return output;
    }
}
```

## Building and deploying your function

You deploy actions to this Java runtime the same way you deploy actions to runtimes from the Apache OpenWhisk project.

Here is an example Bash script for deploying to IBM Cloud Functions from an automated context (such as a CI/CD system). Replace the values marked `<like_this>` with values for your function. Replace <tag> with the latest version of [the runtime image hosted on Docker Hub](https://hub.docker.com/repository/docker/mwelke/openwhisk-runtime-java-19/tags?page=1&ordering=last_updated).

The script is meant to be run interactively from a machine that already has the `ibmcloud` CLI tool installed and authenticated (including the IBM Cloud Functions plugin). If you want to deploy from an automated context such as a GitHub Actions workflow, you will need to update it accordingly.

```bash
#/bin/bash

REGION="<region>"
RESOURCE_GROUP="<resource_group>"
FUNCTIONS_NAMESPACE="<functions_namespace>"
ACTION_NAME="my-function"

BUILD_DIR="lib/build"
JAR_PATH="${BUILD_DIR}/libs/lib-all.jar"

rm -r $BUILD_DIR 2> /dev/null

./gradlew "shadowJar"

ibmcloud target -r $REGION
ibmcloud target -g $RESOURCE_GROUP
ibmcloud fn namespace target $FUNCTIONS_NAMESPACE

ibmcloud fn action update $ACTION_NAME $JAR_PATH \
  --main "com.myfunc.MyFunction" \
  --docker "mwelke/openwhisk-runtime-java-19:<tag>"
```

## Dependencies included in the runtime

The runtime contains the following Maven dependencies, so that they can be used by functions deployed to the runtime without them having to be included in the JAR file deployed:

```gradle
implementation platform('com.google.cloud:libraries-bom:26.2.0')
implementation 'com.google.cloud:google-cloud-bigquery'
```

For example, to use the dependency `com.google.cloud:google-cloud-bigquery` in your function, you would add the dependency to your `build.gradle` file using `compile` instead of `implementation`, like this:

```gradle
compile platform('com.google.cloud:libraries-bom:26.2.0')
compile 'com.google.cloud:google-cloud-bigquery'
```

If you want to use a dependency that is not included in the runtime, you must use `implementation`. Take note of the size of the dependency in the built JAR file, so that you stay within the size limit for deployed action artifacts set up in your OpenWhisk installation.

For more information on Gradle dependencies, see [Declaring dependencies](https://docs.gradle.org/current/userguide/declaring_dependencies.html).

### Want more dependencies to be included?

Open an issue!
