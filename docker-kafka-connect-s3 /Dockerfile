FROM --platform=linux/amd64 confluentinc/cp-kafka-connect:7.5.3 as cp
ARG GITHUB_PACKAGES_TOKEN
ARG TRANSFORMER_VERSION="0.19.0"

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-s3:10.4.2
RUN confluent-hub install --no-prompt confluentinc/connect-transforms:1.4.3

FROM quay.io/strimzi/kafka:0.34.0-kafka-3.3.1

USER root:root

RUN mkdir -p /opt/kafka/plugins/kafka-connect-s3 && \
 mkdir -p /opt/kafka/plugins/connect-transforms

COPY --from=cp /usr/share/confluent-hub-components/confluentinc-kafka-connect-s3/lib /opt/kafka/plugins/kafka-connect-s3/

USER 1001
