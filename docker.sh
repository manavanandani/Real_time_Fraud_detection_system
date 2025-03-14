Zookeeper-
docker run -d --name zookeeper --network ksql-network `
  -e ZOOKEEPER_CLIENT_PORT=2181 `
  -e ZOOKEEPER_TICK_TIME=2000 `
  confluentinc/cp-zookeeper:latest

Kafka-
  docker run -d --name kafka --network ksql-network `
  -e KAFKA_BROKER_ID=1 `
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 `
  -e KAFKA_LISTENERS="PLAINTEXT://0.0.0.0:9092,PLAINTEXT_INTERNAL://0.0.0.0:29092" `
  -e KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://localhost:9092,PLAINTEXT_INTERNAL://kafka:29092" `
  -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP="PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT" `
  -e KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT_INTERNAL `
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 `
  -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 `
  -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 `
  -p 9092:9092 -p 29092:29092 `
  confluentinc/cp-kafka:latest

Ksqldb-server-
docker run -d --name ksqldb-server --network ksql-network `
  -e KSQL_CONFIG_DIR="/etc/ksqldb" `
  -e KSQL_BOOTSTRAP_SERVERS="PLAINTEXT_INTERNAL://kafka:29092" `
  -e KSQL_HOST_NAME="ksqldb-server" `
  -e KSQL_LISTENERS="http://0.0.0.0:8088" `
  -p 8088:8088 `
  confluentinc/cp-ksqldb-server:latest


Create TOPIC-
 docker exec -it kafka kafka-topics --create --topic credit_card_transactions --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

Verify TOPIC exists-
 docker exec -it kafka kafka-topics --list --bootstrap-server localhost:9092

Verify messages are receiving by consumer-
 docker exec -it kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic credit_card_transactions --from-beginning

Access ksqldb cli-
 docker run -it --rm --network ksql-network confluentinc/cp-ksqldb-cli:latest http://ksqldb-server:8088

In ksqldb cli-
SHOW TOPICS;
CREATE STREAM transactions (transaction_id VARCHAR,card_number VARCHAR,amount DOUBLE,currency VARCHAR,transaction_type VARCHAR,timestamp VARCHAR,location STRUCT<city VARCHAR, state VARCHAR>,merchant VARCHAR,device_type VARCHAR) WITH (KAFKA_TOPIC='credit_card_transactions',VALUE_FORMAT='JSON');
SELECT * FROM transactions EMIT CHANGES;






