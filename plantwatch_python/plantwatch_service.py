#!/usr/bin/python3

import pika
import logging
import ast
import datetime
import json
import sys
import reading_pb2
import heartbeat_pb2
import command_pb2
from google.protobuf.json_format import MessageToJson
from google.protobuf.json_format import MessageToDict
from pymongo import MongoClient
from dotenv import dotenv_values

env_vars = dotenv_values(".env")

# This class represents the state and functionality of the Plantwatch backend service
class PlantwatchService:
    def __init__(self):
        try:
            self.client = MongoClient(env_vars["MONGO_SERVER"], 27017)
            self.db = self.client.plantwatch
            self.readings = self.db.readings
            self.devices = self.db.devices
        except Exception as error:
            logging.error("An error happened when trying to open database connection")
            logging.error(error)
            sys.exit("Exiting gracefully. Can't operate without database connection")
        try:
            self.creds = pika.credentials.PlainCredentials(env_vars["RABBITMQ_USER"], env_vars["RABBITMQ_PASSWORD"], erase_on_connect=False)
            self.connection = pika.BlockingConnection(pika.ConnectionParameters(env_vars["RABBITMQ_SERVER"], credentials=self.creds))
            self.channel = self.connection.channel()
            self.channel.queue_declare("plantwatch_readings")
            self.channel.basic_consume(queue="plantwatch_readings", auto_ack=True, on_message_callback=self.readingReceived)
            self.channel.basic_consume(queue="plantwatch_heartbeat", auto_ack=True, on_message_callback=self.heartbeatReceived)
            self.channel.start_consuming()
        except Exception as error:
            logging.error("An error happened when trying to open RabbitMQ connection")
            logging.error(error)
            sys.exit("Exiting gracefully. Can't operate without RabbitMQ connection")

    # This is the method called when a message is received on the reading channel. It stores the reading in the database.
    def readingReceived(self, ch, method, properties, body):
        logging.info(f"Received a reading: {body}")
        try:
            readingMsg = reading_pb2.Reading()
            readingMsg.ParseFromString(body)
            reading = MessageToDict(readingMsg)
        except Exception as error:
            logging.error("An error happened when trying to parse reading message. The message may have been malformed.")
            logging.error(error)
            logging.error("This is not a catatastrophic error. Continuing...")
            return
        try:
            self.readings.insert_one(reading)
        except Exception as error:
            logging.error("An error happened when trying to add a reading to the database")
            logging.error(error)
            logging.error("This is not a catatastrophic error. Continuing...")
        
    # This is the method called when a message is received on the heartbeat channel. If a device has never been seen before, it is added to the devices collection in the database. If it has been seen before, it updates the latest reading.
    def heartbeatReceived(self, ch, method, properties, body):
        logging.info(f"Received a heartbeat: {body}")
        try:
            device = ast.literal_eval(body.decode('UTF-8'))
        except Exception as error:
            logging.error("An error happened when trying to parse heartbeat message. The message may have been malformed.")
            logging.error(error)
            logging.error("This is not a catatastrophic error. Continuing...")
            return
        try:
            foundDevice = self.devices.find_one({'_id' : device['_id']})
        except Exception as error:
            logging.error("An error happened while looking up a device in the database")
            logging.error(error)
            logging.error("This is not a catastrophic error. Continuing...")
            return
        if (foundDevice):
            logging.info(f"Device with id {device['_id']} already exists in database")
            if ("parameters" in foundDevice):
                logging.info(f"Parameters are set for {device['_id']}: {foundDevice['parameters']}, sending command message")
                try:
                    self.channel.basic_publish(exchange='', routing_key=str(device['_id']), body=str(json.dumps(foundDevice['parameters'])))
                except Exception as error:
                    logging.error("An error happened when sending command message")
                    logging.error(error)
                    logging.error("This is not a catastrophic error. Continuing...")
        try:
            self.devices.update_one({'_id': device['_id']},{"$set":{'timestamp':str(datetime.datetime.utcnow()), 'latestReading':device['latestReading']}}, upsert=True)
        except Exception as error:
            logging.error("An error happened when updating the device in the database")
            logging.error(error)
            logging.error("This is not a catastrophic error. Continuing...")

def main():
    logging.basicConfig(level=logging.INFO)
    plantwatch = PlantwatchService()

if (__name__ == "__main__"):
    main()