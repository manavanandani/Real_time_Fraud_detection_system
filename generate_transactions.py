import json
import time
import faker
from kafka import KafkaProducer

fake = faker.Faker()

def generate_transaction():
    return {
        "card_number": fake.credit_card_number(),
        "amount": float(fake.pydecimal(positive=True, min_value=1, max_value=1000, right_digits=2)),
        "timestamp": fake.iso8601(),
        "location": {
            "city": fake.city(),
            "state": fake.state_abbr()
        },
        "merchant": fake.company()
    }

producer = KafkaProducer(bootstrap_servers="localhost:9092", value_serializer=lambda v: json.dumps(v).encode("utf-8"))

while True:
    transaction = generate_transaction()
    producer.send("credit_card_transactions", transaction)
    producer.flush()
    print(f"Sent: {transaction}")
    time.sleep(1)
