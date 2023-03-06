#/usr/bin/python3

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

class Reading:
    reading_data = {}
    def __init__(self, temperature, humidity, moisture, uvIndex):
        self.reading_data["readingId"] = str(uuid4())
        self.reading_data["deviceId"] = str(deviceId)
        self.reading_data["timestamp"] = str(datetime.datetime.utcnow())
        self.reading_data["temperature"] = temperature
        self.reading_data["humidity"] = humidity
        self.reading_data["moisture"] = moisture
        self.reading_data["uvIndex"] = uvIndex

class Setting:
    setting_data = {}
    def __init__(self, minTemp, maxTemp, minHum, maxHum, minMoist, maxMoist, minUv, maxUv):
        self.setting_data["minTemp"] = minTemp
        self.setting_data["maxTemp"] = maxTemp
        self.setting_data["minHum"] = minHum
        self.setting_data["maxHum"] = maxHum
        self.setting_data["minMoist"] = minMoist
        self.setting_data["maxMoist"] = maxMoist
        self.setting_data["minUv"] = minUv
        self.setting_data["maxUv"] = maxUv

logging.basicConfig(level=logging.INFO)

env_vars = dotenv_values(".env")

deviceId = uuid4()

i2cbus = smbus.SMBus(1)

DHT20_I2C_ADDRESS = 0x38
SI1151 = grove_si115x()
moistureSensor = GroveMoistureSensor(0)

currentSetting = None
pumpStatus = False
heaterStatus = False
ventStatus = False

def sendReadingMessage(readingData):
    creds = pika.credentials.PlainCredentials(env_vars["RABBITMQ_USER"], env_vars["RABBITMQ_PASSWORD"], erase_on_connect=False)
    connection = pika.BlockingConnection(pika.ConnectionParameters(env_vars["RABBITMQ_SERVER"], credentials=creds))
    channel = connection.channel()
    channel.queue_declare(queue="plantwatch_readings")
    channel.basic_publish(exchange='', routing_key="plantwatch_readings", body=str(readingData))
    logging.info("Sent reading")
    connection.close()

def getCommandMessage():
    creds = pika.credentials.PlainCredentials(env_vars["RABBITMQ_USER"], env_vars["RABBITMQ_PASSWORD"], erase_on_connect=False)
    connection = pika.BlockingConnection(pika.ConnectionParameters(env_vars["RABBITMQ_SERVER"], credentials=creds))
    channel = connection.channel()
    channel.queue_declare(queue=str(deviceId))
    method_frame, header_frame, body = channel.basic_get(queue=str(deviceId))
    if method_frame:
        channel.basic_ack(method_frame.delivery_tag)
        receivedData = json.loads(body)
        logging.info("Command received")
        currentSetting = Setting(receivedData["minTemp"], receivedData["maxTemp"], receivedData["minHum"], receivedData["maxHum"], receivedData["minMoist"], receivedData["maxMoist"], receivedData["minUv"], receivedData["maxUv"])
    else:
        logging.info("No command data received")
    connection.close()

# Adapted from this SO answer: https://raspberrypi.stackexchange.com/questions/133457/how-can-rpi4b-use-python-to-talk-to-the-i2c-dht20-sht20-temperature-and-humidi
def getTemperatureAndHumidity(address):
    i2cbus.write_i2c_block_data(address,0xac, [0x33, 0x00])
    time.sleep(0.1)
    tempHumData = i2cbus.read_i2c_block_data(address, 0x71, 7)
    Traw = ((tempHumData[3] & 0xf) << 16) + (tempHumData[4] << 8) + tempHumData[5]
    temperature = 200*float(Traw)/2**20 - 50
    Hraw = ((tempHumData[3] & 0xf0) >> 4) + (tempHumData[1] << 12) + (tempHumData[2] << 4)
    humidity = 100*float(Hraw)/2**20
    return temperature,humidity

def getUVIndex():
    return SI1151.ReadHalfWord_UV()

def getMoistureStrength():
    return moistureSensor.moisture

def main():
    logging.info(f"Device started at {str(datetime.datetime.utcnow())}")
    logging.info(f"This device is {deviceId}")
    while True:
        temperature,humidity = getTemperatureAndHumidity(DHT20_I2C_ADDRESS)
        uvIndex = getUVIndex()
        moisture = getMoistureStrength()
        newReading = Reading(temperature=temperature, humidity=humidity, moisture=moisture, uvIndex=uvIndex)
        logging.info(f"Took a reading: {str(newReading.reading_data)}")
        sendReadingMessage(newReading.reading_data)
        currentSetting = getCommandMessage()
        if (currentSetting):
            if(temperature < currentSetting["minTemp"]):
                heaterStatus = True
            elif(temperature > currentSetting["maxTemp"]):
                heaterStatus = False
            if(humidity < currentSetting["minHum"]):
                ventStatus = False
            elif(humidity > currentSetting["maxHum"]):
                ventStatus = True
        time.sleep(5)

if (__name__ == "__main__"):
    main()
