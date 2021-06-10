## Execute upstream tests of Optaweb projects

#### 1. Create a bxms-deliverable-list.properties in a top-level directory containing following entries:
- link to reference-implementation.zip

    `rhdm.reference-implementation.latest.url=http://rcm-guest.app.eng.bos.redhat.com/rcm-guest/staging/rhdm/RHDM-7.7.0.CR1/rhdm-7.7.0-reference-implementation.zip`
- product micro version:

    `PRODUCT_MICRO_VERSION=7.7.0`

#### 2. Define a `PRODUCT` environment property that matches the tested distribution, e.g. 
`export PRODUCT=RHDM`

#### 3. Run from the top-level module by:
`mvn clean verify -Poptaweb,employee-rostering,openshift -Ddroolsjbpm.version=${KIE_VERSION}` 
or
`mvn clean verify -Poptaweb,employee-rostering,on-premise -Ddroolsjbpm.version=${KIE_VERSION}`
where `KIE_VERSION` is a version of productized KIE artifacts, e.g. `7.33.0.Final-redhat-00001`

If you are running the tests on CodeReady Containers, add the following maven properties:

`-Dopenshift.api-url=https://api.openshift.apps-crc.testing:6443 -Dopenshift.user=developer -Dopenshift.password=developer`
