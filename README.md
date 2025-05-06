# WildFly Docker image

This is an example Dockerfile with [WildFly application server](http://wildfly.org/).

---
**NOTE**

Official builds for this image are now published to [https://quay.io/wildfly/wildfly](https://quay.io/wildfly/wildfly).  
Previous repository at [https://hub.docker.com/r/jboss/wildfly](https://hub.docker.com/r/jboss/wildfly) is no longer updated with new images.

---

## WildFly Images

WildFly publishes images to run the application server with different JDK versions.
The tag of the image identifies the version of WildFly as well as the JDK version in the images.

For each release of WildFly (e.g. `28.0.0.Final`), there are fixed tags for each supported JDK version:

* `quay.io/wildfly/wildfly:28.0.0.Final-jdk11`
* `quay.io/wildfly/wildfly:28.0.0.Final-jdk17`
* `quay.io/wildfly/wildfly:28.0.0.Final-jdk20`

There are also floating tags available to pull the _latest release of WildFly on the various JDK_:

* `quay.io/wildfly/wildfly:latest-jdk11`
* `quay.io/wildfly/wildfly:latest-jdk17`
* `quay.io/wildfly/wildfly:latest-jdk20`

Finally, there is the `latest` tag that pull the _latest release of WildFly on the latest LTS JDK version_:

* `quay.io/wildfly/wildfly:latest`

---
**NOTE**

_This floating tag may correspond to a different JDK version in future releases of WildFly images._

Instead of using the `latest` tag, we recommend to use the floating tag with the JDK version mention to guarantee the use of the same JDK version across WildFly releases (e.g. `latest-jdk17`).

---


## Usage

To boot in standalone mode

    docker run -p 8080:8080 -it quay.io/wildfly/wildfly
    
To boot in domain mode

    docker run -it quay.io/wildfly/wildfly /opt/jboss/wildfly/bin/domain.sh -b 0.0.0.0 -bmanagement 0.0.0.0

## Application deployment

With the WildFly server you can [deploy your application in multiple ways](https://docs.jboss.org/author/display/WFLY8/Application+deployment):

1. You can use CLI
2. You can use the web console
3. You can use the management API directly
4. You can use the deployment scanner

The most popular way of deploying an application is using the deployment scanner. In WildFly this method is enabled by default and the only thing you need to do is to place your application inside of the `deployments/` directory. It can be `/opt/jboss/wildfly/standalone/deployments/` or `/opt/jboss/wildfly/domain/deployments/` depending on [which mode](https://docs.jboss.org/author/display/WFLY8/Operating+modes) you choose (standalone is default in the `jboss/wildfly` image -- see above).

The simplest and cleanest way to deploy an application to WildFly running in a container started from the `quay.io/wildfly/wildfly` image is to use the deployment scanner method mentioned above.

To do this you just need to extend the `quay.io/wildfly/wildfly` image by creating a new one. Place your application inside the `deployments/` directory with the `ADD` command (but make sure to include the trailing slash on the deployment folder path, [more info](https://docs.docker.com/reference/builder/#add)). You can also do the changes to the configuration (if any) as additional steps (`RUN` command).  

[A simple example](https://github.com/goldmann/wildfly-docker-deployment-example) was prepared to show how to do it, but the steps are following:

1. Create `Dockerfile` with following content:

        FROM quay.io/wildfly/wildfly
        ADD your-awesome-app.war /opt/jboss/wildfly/standalone/deployments/
2. Place your `your-awesome-app.war` file in the same directory as your `Dockerfile`.
3. Run the build with `docker build --tag=wildfly-app .`
4. Run the container with `docker run -it wildfly-app`. Application will be deployed on the container boot.

This way of deployment is great because of a few things:

1. It utilizes Docker as the build tool providing stable builds
2. Rebuilding image this way is very fast (once again: Docker)
3. You only need to do changes to the base WildFly image that are required to run your application

## Logging

Logging can be done in many ways. [This blog post](https://goldmann.pl/blog/2014/07/18/logging-with-the-wildfly-docker-image/) describes a lot of them.

## Customizing configuration

Sometimes you need to customize the application server configuration. There are many ways to do it and [this blog post](https://goldmann.pl/blog/2014/07/23/customizing-the-configuration-of-the-wildfly-docker-image/) tries to summarize it.

## Extending the image with the management console

To be able to create an admin user to access the management console create a `Dockerfile` with the following content

    FROM quay.io/wildfly/wildfly

    RUN --mount=type=secret,id=ADMIN_USER,env=ADMIN_USER,required=true             \
        --mount=type=secret,id=ADMIN_PASSWORD,env=ADMIN_PASSWORD,required=true     \
        $JBOSS_HOME/bin/add-user.sh -u ${ADMIN_USER} -p ${ADMIN_PASSWORD} --silent

    CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]

Then you can build the image:

    ADMIN_USER=alice ADMIN_PASSWORD=Admin#70365 docker build --tag=jboss/wildfly-admin --secret id=ADMIN_USER --secret id=ADMIN_PASSWORD .

Run it with:

    docker run -p 8080:8080 -p 9990:9990 -it jboss/wildfly-admin

Management console will be available on the port `9990` of the container and you can connect with `alice` : `Admin#70365`.

## Building on your own

You don't need to do this on your own, because we prepared a trusted build for this repository, but if you really want:

    docker build --rm=true --tag=jboss/wildfly .

## Image internals [updated May 15, 2023]

This image extends the [`eclipse-temurin`](https://hub.docker.com/_/eclipse-temurin) JDK. Starting with JDK 11, this base OS used is [`ubi9-minimal`](https://catalog.redhat.com/software/containers/ubi9-minimal/61832888c0d15aff4912fe0d). A UBI 9 image to validate the build arguments provided.

This image installs the wildfly server and sets up the JBoss environment similar to [`jboss/base`](https://github.com/jboss-dockerfiles/base) image. Please refer to the README.md for selected images and more info.

The server is run as the `jboss` user which has the uid/gid set to `1000`.

WildFly is installed in the `/opt/jboss/wildfly` directory.

## Release Procedure

The procedure to release the WildFly container images is described in the [Release-Procedure wiki page](https://github.com/wildfly/wildfly-container/wiki/Release-Procedure).

## Source

The source is [available on GitHub](https://github.com/wildfly/wildfly-container).

## Issues

Please report any issues or file RFEs on [GitHub](https://github.com/wildfly/wildfly-container/issues).
