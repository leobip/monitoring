from confluent_kafka import Producer

conf = {
    'bootstrap.servers': '192.168.49.2:30092,192.168.49.2:30093,192.168.49.2:30094',
    'security.protocol': 'SASL_PLAINTEXT',
    'sasl.mechanisms': 'SCRAM-SHA-256',
    'sasl.username': 'user1',
    'sasl.password': 'XExFpeC9iu'
}

producer = Producer(conf)

def delivery_report(err, msg):
    if err is not None:
        print(f'Message delivery failed: {err}')
    else:
        print(f'Message delivered to {msg.topic()} [{msg.partition()}]')

producer.produce('matrics', key='key1', value='Hola desde local!', callback=delivery_report)
producer.flush()
