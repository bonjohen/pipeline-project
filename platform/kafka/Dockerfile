FROM confluentinc/cp-kafka:7.6.0

# Install Zookeeper
USER root
RUN microdnf install -y java-11-openjdk-headless wget tar && \
    wget https://archive.apache.org/dist/zookeeper/zookeeper-3.8.3/apache-zookeeper-3.8.3-bin.tar.gz && \
    tar -xzf apache-zookeeper-3.8.3-bin.tar.gz -C /opt && \
    mv /opt/apache-zookeeper-3.8.3-bin /opt/zookeeper && \
    rm apache-zookeeper-3.8.3-bin.tar.gz && \
    mkdir -p /var/lib/zookeeper/data && \
    chown -R appuser:appuser /var/lib/zookeeper

# Create Zookeeper config
RUN echo "tickTime=2000" > /opt/zookeeper/conf/zoo.cfg && \
    echo "dataDir=/var/lib/zookeeper/data" >> /opt/zookeeper/conf/zoo.cfg && \
    echo "clientPort=2181" >> /opt/zookeeper/conf/zoo.cfg && \
    echo "maxClientCnxns=60" >> /opt/zookeeper/conf/zoo.cfg

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo '/opt/zookeeper/bin/zkServer.sh start' >> /start.sh && \
    echo 'sleep 5' >> /start.sh && \
    echo '/etc/confluent/docker/run' >> /start.sh && \
    chmod +x /start.sh

ENV KAFKA_BROKER_ID=1
ENV KAFKA_ZOOKEEPER_CONNECT=localhost:2181
ENV KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092
ENV KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://pipeline-kafka.internal:9092
ENV KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
ENV KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1
ENV KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1
ENV KAFKA_AUTO_CREATE_TOPICS_ENABLE=true

CMD ["/start.sh"]
