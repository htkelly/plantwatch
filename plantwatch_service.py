#!/usr/bin/python3

import pika
import logging
import ast
import datetime
from pymongo import MongoClient
from dotenv import dotenv_values

logging.basicConfig(level=logging.INFO)

env_vars = dotenv_values(".env")

class PlantwatchService:
    def __init__(self):
        self.client = MongoClient(env_vars["MONGO_SERVER"], 27017)
        self.db = self.client.plantwatch
        self.readings = self.db.readings
        self.devices = self.db.devices
        self.creds = pika.credentials.PlainCredentials(env_vars["RABBITMQ_USER"], env_vars["RABBITMQ_PASSWORD"], erase_on_connect=False)
        self.connection = pika.BlockingConnection(pika.ConnectionParameters(env_vars["RABBITMQ_SERVER"], credentials=self.creds))
        self.channel = self.connection.channel()
        self.channel.queue_declare("plantwatch_readings")
        self.channel.basic_consume(queue="plantwatch_readings", auto_ack=True, on_message_callback=self.readingReceived)
        self.channel.basic_consume(queue="plantwatch_heartbeat", auto_ack=True, on_message_callback=self.heartbeatReceived)
        self.channel.start_consuming()

    def readingReceived(self, ch, method, properties, body):
        logging.info(f"Received a reading: {body}")
        reading = ast.literal_eval(body.decode('UTF-8'))
        self.readings.insert_one(reading)

    def heartbeatReceived(self, ch, method, properties, body):
        logging.info(f"Received a heartbeat: {body}")
        device = ast.literal_eval(body.decode('UTF-8'))
        self.devices.update_one({'deviceId': device['deviceId']},{"$set":{'timestamp':str(datetime.datetime.utcnow()), 'latestReading':device['latestReading']}}, upsert=True)

def main():
    plantwatch = PlantwatchService()

if (__name__ == "__main__"):
    main()