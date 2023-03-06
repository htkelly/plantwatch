#!/usr/bin/python3

from uuid import uuid4
import smbus
import logging
import time
import datetime
import pika
import json
from dotenv import dotenv_values
from seeed_si115x import grove_si115x
from grove_moisture_sensor import GroveMoistureSensor
from gpiozero import LED

env_vars = dotenv_values(".env")

class Actuator:
    #For prototyping, these actuators are just LEDs for the moment
    def __init__(self, pin):
        self.led = LED(pin)
        self.state = False
    
    def on(self):
        self.led.on()
        self.state = True

    def off(self):
        self.led.off()
        self.state = False

class Plantwatcher:
    i2cbus = smbus.SMBus(1)
    DHT20_I2C_ADDRESS = 0x38
    lightSensor = grove_si115x()
    moistureSensor = GroveMoistureSensor(0)

    waterPump = Actuator(19)
    heater = Actuator(18)
    cooler = Actuator(23)
    extractorFan = Actuator(6)

    rabbitCreds = pika.credentials.PlainCredentials(env_vars["RABBITMQ_USER"], env_vars["RABBITMQ_PASSWORD"], erase_on_connect=False)
    rabbitConnection = None
    rabbitChannel = None

    def __init__(self):
        self.id = uuid4()
        self.initTime = datetime.datetime.utcnow()
        self.latestReading = None
        self.parameters = {}
        self.rabbitConnection = pika.BlockingConnection(pika.ConnectionParameters(env_vars["RABBITMQ_SERVER"], credentials=self.rabbitCreds))
        self.rabbitChannel = self.rabbitConnection.channel()
        logging.info(f"Device initialized with id {self.id} at {str(self.initTime)}")

    # Adapted from this SO answer: https://raspberrypi.stackexchange.com/questions/133457/how-can-rpi4b-use-python-to-talk-to-the-i2c-dht20-sht20-temperature-and-humidi
    def getTemperatureAndHumidity(self):
        self.i2cbus.write_i2c_block_data(self.DHT20_I2C_ADDRESS,0xac, [0x33, 0x00])
        time.sleep(0.1)
        tempHumData = self.i2cbus.read_i2c_block_data(self.DHT20_I2C_ADDRESS, 0x71, 7)
        Traw = ((tempHumData[3] & 0xf) << 16) + (tempHumData[4] << 8) + tempHumData[5]
        temperature = 200*float(Traw)/2**20 - 50
        Hraw = ((tempHumData[3] & 0xf0) >> 4) + (tempHumData[1] << 12) + (tempHumData[2] << 4)
        humidity = 100*float(Hraw)/2**20
        return temperature,humidity

    def getUVIndex(self):
        return self.lightSensor.ReadHalfWord_UV()

    def getMoistureStrength(self):
        return self.moistureSensor.moisture

    def sendReadingMessage(self, readingData):
        self.rabbitChannel.queue_declare(queue=f"plantwatch_readings")
        self.rabbitChannel.basic_publish(exchange='', routing_key="plantwatch_readings", body=str(readingData))
        logging.info(f"Sent reading id {readingData['readingId']}")

    def getCommandMessage(self):
        self.rabbitChannel.queue_declare(queue=str(self.id))
        method_frame, header_frame, body = self.rabbitChannel.basic_get(queue=str(self.id))
        if method_frame:
            self.rabbitChannel.basic_ack(method_frame.delivery_tag)
            receivedParams = json.loads(body)
            logging.info("Command received")
            self.parameters = receivedParams
        else:
            logging.info("No command data received")

    #The below logic would likely lead to erratic and/or delayed actuator behaviour, but as our actuators are still just LEDs, this will work for proof-of-concept
    def updateActuators(self):
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
            if(self.latestReading.reading_data["moisture"] < self.parameters["minMoist"]):
                self.waterPump.on()
            elif(self.latestReading.reading_data["moisture"] >= self.parameters["maxMoist"]):
                self.waterPump.on()

class Reading:
    reading_data = {}
    def __init__(self, deviceId, temperature, humidity, moisture, uvIndex):
        self.reading_data["readingId"] = str(uuid4())
        self.reading_data["deviceId"] = str(deviceId)
        self.reading_data["timestamp"] = str(datetime.datetime.utcnow())
        self.reading_data["temperature"] = temperature
        self.reading_data["humidity"] = humidity
        self.reading_data["moisture"] = moisture
        self.reading_data["uvIndex"] = uvIndex

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
        watcher.sendReadingMessage(newReading.reading_data)
        watcher.getCommandMessage()
        watcher.updateActuators()
        time.sleep(5)

if (__name__ == "__main__"):
    main()
