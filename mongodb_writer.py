import json
from pymongo import MongoClient
from kafka import KafkaConsumer

client = MongoClient('localhost', 27017)
db = client['fraud_transactions']
collection = db['transactions']

consumer = KafkaConsumer(
    'flag_transactions',
    bootstrap_servers='localhost:9092',
    auto_offset_reset='earliest',
    value_deserializer=lambda v: json.loads(v.decode('utf-8'))
)

print("Listening for flagged transactions...")

for msg in consumer:
    transaction = msg.value
    print(f"Inserting transaction: {transaction}")
    collection.insert_one(transaction)