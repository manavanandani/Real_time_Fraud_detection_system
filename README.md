# Real-time Credit Card Fraud Detection System

## Overview
This project demonstrates a real-time credit card fraud detection system using Apache Kafka, Kafka Streams (KSQLDB), MongoDB, and Apache Flink. The system ingests simulated credit card transaction data, analyzes it for suspicious patterns, and generates alerts in real time.

## Table of Contents
- [Environment Setup](#environment-setup)
- [Data Generation](#data-generation)
- [Kafka Integration](#kafka-integration)
- [Fraud Detection with KSQLDB](#fraud-detection-with-ksqldb)
- [MongoDB Integration](#mongodb-integration)
- [Real-time Analytics with Flink](#real-time-analytics-with-flink)
- [Challenges and Insights](#challenges-and-insights)

## Environment Setup
To set up the environment, follow these steps:
1. Install the required dependencies:
```
pip install kafka-python confluent-kafka ksql kafka-streams faker pyflink pymongo
```
2. Start a local Kafka cluster using Docker:
```
docker-compose up -d kafka zookeeper
```
3. Verify that all containers are running.

## Data Generation
Using the `faker` library, simulated transaction data was generated with the following attributes:
- Card Number
- Transaction Amount
- Timestamp
- Location (City, State)
- Merchant Category

### Sample Code for Data Generation
```python
import faker
from kafka import KafkaProducer
import json
import time

fake = faker.Faker()

def generate_transaction():
    return {
        "card_number": fake.credit_card_number(),
        "amount": fake.pydecimal(positive=True, min_value=1, max_value=1000, right_digits=2),
        "timestamp": fake.date_time().isoformat(),
        "location": {"city": fake.city(), "state": fake.state_abbr()},
        "merchant": fake.company()
    }

producer = KafkaProducer(bootstrap_servers="localhost:9092")
while True:
    transaction = generate_transaction()
    producer.send("credit_card_transactions", json.dumps(transaction).encode("utf-8"))
    producer.flush()
    time.sleep(1)
```

## Kafka Integration
A Kafka topic named `credit_card_transactions` was created to receive the simulated transaction data. The following steps were performed:
- Created the topic using the Kafka console producer.
- Verified the topic creation by listing available topics.

## Fraud Detection with KSQLDB
A KSQLDB stream was created to consume data from the `credit_card_transactions` topic:
```sql
CREATE STREAM transactions (
    card_number VARCHAR,
    amount DOUBLE,
    location VARCHAR,
    timestamp TIMESTAMP
) WITH (KAFKA_TOPIC = 'credit_card_transactions', VALUE_FORMAT = 'JSON');
```
### Fraud Detection Logic
A User Defined Function (UDF) was created to detect fraud based on these rules:
- Transactions exceeding $500.
- Transactions occurring in unusual locations.

```sql
CREATE FUNCTION is_fraud(transaction TRANSACTIONS) RETURNS BOOLEAN AS $$
    return transaction.amount > 500 OR transaction.location != 'San Francisco';
$$;

CREATE STREAM flagged_transactions WITH (KAFKA_TOPIC = 'flagged_transactions') AS
SELECT card_number, amount, location, timestamp
FROM transactions
WHERE is_fraud(transactions);
```

## MongoDB Integration
A Python script (`mongodb_writer.py`) was developed to consume flagged transactions and store them in MongoDB.

### Sample Code for MongoDB Integration
```python
from pymongo import MongoClient
from kafka import KafkaConsumer
import json

client = MongoClient('localhost', 27017)
db = client['fraud_detection']
collection = db['flagged_transactions']

consumer = KafkaConsumer('flagged_transactions', bootstrap_servers='localhost:9092')
for msg in consumer:
    transaction = json.loads(msg.value)
    collection.insert_one(transaction)
```

## Real-time Analytics with Flink
Apache Flink was used to perform analytics on the flagged transactions.

### Sample Flink SQL Code
```sql
SELECT
    window_start,
    window_end,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM (
    SELECT
        FLOOR(transaction_time TO SECOND) AS window_start,
        CEIL(transaction_time TO SECOND) AS window_end,
        amount
    FROM transactions
)
GROUP BY TUMBLE(window_start, window_end, INTERVAL '10' SECOND);
```

### Sample PyFlink Code
```python
from pyflink.table import StreamTableEnvironment, EnvironmentSettings

settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
table_env = StreamTableEnvironment.create(environment_settings=settings)

table_env.sql("""
    CREATE TABLE transactions (
        card_number STRING,
        amount DECIMAL(10, 2),
        timestamp TIMESTAMP(3),
        location ROW<city STRING, state STRING>,
        merchant STRING
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'credit_card_transactions',
        'scan.startup.mode' = 'earliest',
        'bootstrap.servers' = 'localhost:9092',
        'format' = 'json'
    )
""")
```

## Challenges and Insights
### Challenges Faced
- Ensuring smooth communication between Kafka producer and consumer.
- Maintaining data synchronization between Kafka and MongoDB.

### Insights Gained
- Real-time analytics is crucial to identifying and preventing fraud effectively.
- The combination of Kafka, MongoDB, and Flink offers powerful solutions but requires careful integration for optimal performance.

### Best Practices
- Implement robust error handling.
- Ensure data is validated before insertion into MongoDB.
- Adopt asynchronous processing techniques to improve system performance.

## Blog Link
For a detailed breakdown, refer to the blog: [Real-time Credit Card Fraud Detection System](https://github.com/manavanandani/Real_time_Fraud_detection_system)


