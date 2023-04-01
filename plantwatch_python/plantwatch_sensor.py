#!/usr/bin/python3

from bson import ObjectId
import smbus
import sys
import logging
import time
import datetime
import pika
import json
from google.protobuf import json_format
import reading_pb2
from dotenv import dotenv_values
from seeed_si115x import grove_si115x
from grove_moisture_sensor import GroveMoistureSensor
from grove_relay import GroveRelay
from gpiozero import LED

env_vars = dotenv_values(".env")

# This class is used to represent actuators with an LED, for development and prototyping purposes
class TestActuator:
    def __init__(self, pin):
        self.led = LED(pin)
        self.state = False
    
    def on(self):
        self.led.on()
        self.state = True

    def off(self):
        self.led.off()
        self.state = False

# A simple class with a dictionary for storing reading values
class Reading:
    reading_data = {}
    def __init__(self, deviceId, temperature, humidity, moisture, uvIndex):
        self.reading_data["_id"] = str(ObjectId())
        self.reading_data["deviceId"] = str(deviceId)
        self.reading_data["timestamp"] = str(datetime.datetime.utcnow())
        self.reading_data["temperature"] = temperature
        self.reading_data["humidity"] = humidity
        self.reading_data["moisture"] = moisture
        self.reading_data["uvIndex"] = uvIndex

# This class represents the status and functionality of the sensor/controller device itself
class Plantwatcher:
    def __init__(self):
        try:
            self.id = ObjectId()
            self.initTime = datetime.datetime.utcnow()
        except Exception as error:
            logging.error("An error happened while setting object ID and initTime")
            logging.error(error)
            sys.exit("Exiting. Could not initialize.")
        try:
            self.i2cbus = smbus.SMBus(1)
            self.DHT20_I2C_ADDRESS = 0x38
            self.lightSensor = grove_si115x()
            self.parameters = {}
            self.latestReading = None
        except Exception as error:
            logging.error("An error happened while initializing I2C devices")
            logging.error(error)
            sys.exit("Exiting gracefully. Could not initialize I2C devices")
        try:
            self.moistureSensor = GroveMoistureSensor(0)
        except Exception as error:
            logging.error("An error happened while initializing moisture sensor")
            logging.error(error)
            sys.exit("Exiting gracefully. Could not initialize moisture sensor")
        try:
            self.waterPump = GroveRelay(12)
        except Exception as error:
            logging.error("An error happened while initializing water pump")
            logging.error(error)
            sys.exit("Exiting gracefully. Could not initialize water pump")
        try:
            self.heater = TestActuator(18)
            self.cooler = TestActuator(23)
            self.extractorFan = TestActuator(6)
        except Exception as error:
            logging.error("An error happened while initializing test actuators")
            logging.error(error)
            sys.exit("Exiting gracefully. Could not initialize test actuators")
        try:
            self.rabbitCreds = pika.credentials.PlainCredentials(env_vars["RABBITMQ_USER"], env_vars["RABBITMQ_PASSWORD"], erase_on_connect=False)
            self.rabbitConnection = pika.BlockingConnection(pika.ConnectionParameters(env_vars["RABBITMQ_SERVER"], credentials=self.rabbitCreds))
            self.rabbitChannel = self.rabbitConnection.channel()
        except Exception as error:
            logging.error("An error happened while connecting to Rabbit MQ")
            logging.error(error)
            sys.exit("Exiting gracefully. Could not connect to Rabbit MQ")
        logging.info(f"Device initialized with id {self.id} at {str(self.initTime)}")

    # Adapted from this SO answer: https://raspberrypi.stackexchange.com/questions/133457/how-can-rpi4b-use-python-to-talk-to-the-i2c-dht20-sht20-temperature-and-humidi
    # This function reads data from DHT20 sensor and uses bitwise operations/masking to return the data as floats
    def getTemperatureAndHumidity(self):
        try:
            self.i2cbus.write_i2c_block_data(self.DHT20_I2C_ADDRESS,0xac, [0x33, 0x00])
            time.sleep(0.1)
            tempHumData = self.i2cbus.read_i2c_block_data(self.DHT20_I2C_ADDRESS, 0x71, 7)
        except Exception as error:
            logging.error("An error happened while reading data from DHT20 over I2C bus")
            logging.error(error)
            sys.exit("Exiting gracefully. There is a problem with the DHT20 sensor")
        Traw = ((tempHumData[3] & 0xf) << 16) + (tempHumData[4] << 8) + tempHumData[5]
        temperature = 200*float(Traw)/2**20 - 50
        Hraw = ((tempHumData[3] & 0xf0) >> 4) + (tempHumData[1] << 12) + (tempHumData[2] << 4)
        humidity = 100*float(Hraw)/2**20
        return temperature,humidity

    #  Using functionality exposed by the Grove library, this function gets the UV index from the light sensor
    def getUVIndex(self):
        try:
            return self.lightSensor.ReadHalfWord_UV()
        except Exception as error:
            logging.error("An error happened while reading UV index from the light sensor")
            logging.error(error)
            sys.exit("Exiting gracefully. There is a problem with the light sensor")

    # Using functionality exposed by the Grove library, this function returns the voltage in mV across the moisture sensor probes. It returns a value between 0 and 1000 indicating soil moisture content
    def getMoistureStrength(self):
        try:
            return self.moistureSensor.moisture
        except Exception as error:
            logging.error("An error happened while reading soil moisture from the moisture sensor")
            logging.error(error)
            sys.exit("Exiting gracefully. There is a problem with the moisture sensor")

    # This function sends a message to RabbitMQ with a reading from the device
    def sendReadingMessage(self, readingData):
        try:
            readingMsg = reading_pb2.Reading()
            readingJson = json.dumps(readingData)
            json_format.Parse(readingJson, readingMsg)
        except Exception as error:
            logging.error("An error happened while serializing reading message")
            logging.error(error)
            logging.error("This is not a catastrophic error. Continuing...")
        try:
            self.rabbitChannel.queue_declare(queue=f"plantwatch_readings")
            self.rabbitChannel.basic_publish(exchange='', routing_key="plantwatch_readings", body=readingMsg.SerializeToString())
            logging.info(f"Sent reading id {readingData['_id']}")
        except Exception as error:
            logging.error("An error happened while sending a reading message")
            logging.error(error)
            sys.exit("Exiting gracefully. There is a problem with the connection to RabbitMQ")

    # This function checks Rabbit MQ for command messages issued to this device
    def getCommandMessage(self):
        try:
            self.rabbitChannel.queue_declare(queue=str(self.id))
            method_frame, header_frame, body = self.rabbitChannel.basic_get(queue=str(self.id))
        except Exception as error:
            logging.error("An error happened while reading the command queue for this device")
            logging.error(error)
            logging.error("This is not a catastrophic error. Continuing...")
        if method_frame:
            try:
                self.rabbitChannel.basic_ack(method_frame.delivery_tag)
                receivedParams = json.loads(body)
                logging.info("Command received")
                self.parameters = receivedParams
            except Exception as error:
                logging.error("An error happened while acknowledging, parsing, and saving parameters received from RabbitMQ")
                logging.error(error)
                logging.error("This is not a catastrophic error. Continuing...")
        else:
            logging.info("No command data received")

    # This function sends a message to RabbitMQ indicate the device is still online 
    def sendHeartbeatMessage(self):
        deviceInfo={}
        deviceInfo['_id']=str(self.id)
        deviceInfo['latestReading']=self.latestReading.reading_data['_id']
        try:
            self.rabbitChannel.queue_declare(queue=f"plantwatch_heartbeat")
            self.rabbitChannel.basic_publish(exchange='', routing_key="plantwatch_heartbeat", body=json.dumps(deviceInfo))
            logging.info("Sent heartbeat message")
        except Exception as error:
            logging.error("An error occurred while sending a hearbeat message")
            logging.error(error)
            logging.error("This is not a catastrophic error. Continuing...")

    # The below logic could potentially lead to erratic and/or delayed actuator behaviour, but as our test actuators are just LEDs, this will work for proof-of-concept
    def updateTestActuators(self):
        if (bool(self.parameters)):
            if(self.latestReading.reading_data["temperature"] < self.parameters["minTemp"]):
                self.cooler.off()
                self.heater.on()
            elif(self.latestReading.reading_data["temperature"] > self.parameters["maxTemp"]):
                self.heater.off()
                self.cooler.on()
            if(self.latestReading.reading_data["humidity"] < self.parameters["minHum"]):
                self.extractorFan.off()
            elif(self.latestReading.reading_data["humidity"] > self.parameters["maxHum"]):
                self.extractorFan.on()
    
    # Turns the pump on for five seconds. In later iterations, a water flow sensor might be used to stop pumping after a certain volume of water has been pumped, instead of timing
    def updatePump(self):
        if(bool(self.parameters)):
            if(self.latestReading.reading_data["moisture"] < self.parameters["minMoist"]):
                self.waterPump.on()
                time.sleep(5)
                self.waterPump.off()

# Main execution loop
def main():
    logging.basicConfig(level=logging.INFO)
    watcher = Plantwatcher()
    while True:
        temperature,humidity = watcher.getTemperatureAndHumidity()
        uvIndex = watcher.getUVIndex()
        moisture = watcher.getMoistureStrength()
        newReading = Reading(temperature=temperature, deviceId = watcher.id, humidity=humidity, moisture=moisture, uvIndex=uvIndex)
        watcher.latestReading = newReading
        logging.info(f"Took a reading: {str(newReading.reading_data)}")
        watcher.sendHeartbeatMessage()
        watcher.sendReadingMessage(newReading.reading_data)
        watcher.getCommandMessage()
        watcher.updateTestActuators()
        watcher.updatePump()
        time.sleep(5)

if (__name__ == "__main__"):
    main()
