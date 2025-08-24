import os
import argparse
from confluent_kafka import Producer

# ---------- PARSE ARGUMENTS ----------
parser = argparse.ArgumentParser(description="Kafka producer test script")
parser.add_argument('--broker', default=os.getenv('KAFKA_BROKER', '127.0.0.1:9094'))
parser.add_argument('--topic', default=os.getenv('KAFKA_TOPIC', 'metrics'))
parser.add_argument('--secure', action='store_true', help='Use SASL secure connection')
parser.add_argument('--user', default=os.getenv('KAFKA_USER', 'user1'))
parser.add_argument('--password', default=os.getenv('KAFKA_PASSWORD', 'XExFpeC9iu'))
args = parser.parse_args()

# ---------- CONFIG ----------
if args.secure:
    conf = {
        'bootstrap.servers': args.broker,
        'security.protocol': 'SASL_PLAINTEXT',  # o SASL_SSL para TLS
        'sasl.mechanisms': 'SCRAM-SHA-256',
        'sasl.username': args.user,
        'sasl.password': args.password
    }
else:
    conf = {
        'bootstrap.servers': args.broker,
        'security.protocol': 'PLAINTEXT'
    }

producer = Producer(conf)

# ---------- DELIVERY CALLBACK ----------
def delivery_report(err, msg):
    if err is not None:
        print(f'❌ Message delivery failed: {err}')
    else:
        print(f'✅ Message delivered to {msg.topic()} [{msg.partition()}]')

# ---------- SEND MESSAGE ----------
producer.produce(args.topic, key='key1', value='Hello from local host!', callback=delivery_report)
producer.flush()
