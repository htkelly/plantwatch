#!/usr/bin/python3

import pika
import logging
import ast
from pymongo import MongoClient
from dotenv import dotenv_values

logging.basicConfig(level=logging.INFO)

env_vars = dotenv_values(".env")

def readingReceived(ch, method, properties, body):
    logging.info(f"Received a reading: {body}")
    reading = ast.literal_eval(body.decode('UTF-8'))
    readings.insert_one(reading)

client = MongoClient(env_vars["MONGO_SERVER"], 27017)
db = client.plantwatch
readings = db.readings

creds = pika.credentials.PlainCredentials(env_vars["RABBITMQ_USER"], env_vars["RABBITMQ_PASSWORD"], erase_on_connect=False)
connection = pika.BlockingConnection(pika.ConnectionParameters(env_vars["RABBITMQ_SERVER"], credentials=creds))
channel = connection.channel()

def main():
    channel.queue_declare("plantwatch_readings")
    channel.basic_consume(queue="plantwatch_readings", auto_ack=True, on_message_callback=readingReceived)
    channel.start_consuming()

if (__name__ == "__main__"):
    main()