# Optawebs Parent

## Description
This module serves as an invocation point for tests of OptaWeb repositories.

## Usage
Project pom defines profiles that can invoke tests for a particular delivery option.
Download of artifacts is provided by means described in [Module structure](#module-structure).

### Project-sources testing
* optaweb-employee-rostering
  ```
  mvn clean verify \
  -Dtest.type=project-sources \
  -Dproject.sources.artifact=optaweb-employee-rostering \
  -Ddownload.sources.version=<VERSION>
  ```
* optaweb-vehicle-routing
  ```
  mvn clean verify \
  -Dtest.type=project-sources \
  -Dproject.sources.artifact=optaweb-vehicle-routing \
  -Ddownload.sources.version=<VERSION>
  ```
* openshift certification
  ```
  mvn clean verify \
  -DskipTests -Dtest.type=project-sources \
  -Dproject.sources.artifact={optaweb-employee-rostering|optaweb-vehicle-routing} \
  -Ddownload.sources.version=<VERSION> \
  -Dopenshift 
  -Dopenshift.api-url=https://api.crc.testing:6443\
  -Dopenshift.user=developer
  -Dopenshift.password=developer
  -Dsettings.xml.file=../settings/settings.xml
  -Dcontainer.runtime={podman|docker}
  ```
### Sources-zip testing
```
mvn clean verify \
-Dtest.type=sources-zip \
-Ddownload.sources.url=http://link.to/source.zip
```
### Quickstarts-zip testing
```
mvn clean verify \
-Dtest.type=quickstarts-zip \
-Ddownload.sources.url=http://link.to/quickstarts.zip
```
### Additional configuration
* `-Dintegration-tests={true|false}` run integration cypress tests on docker
* `-Dcontainer.runtime={docker|podman}` change runtime

## Module structure
Each of sub-modules contains configuration for Maven Invoker related settings.

Download configuration of particular deliverable is provided by modules
* [run-tests-with-build-sources-zip-download](../run-tests-with-build-sources-zip-download)
  * Used for downloads from arbitrary url.
* [run-tests-with-build-project-sources-dependency-get](../run-tests-with-build-project-sources-dependency-get)
  * Used for tar.gz archives with the classifier project-sources from nexus repository.
