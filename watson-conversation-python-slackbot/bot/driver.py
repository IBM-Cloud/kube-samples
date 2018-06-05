from __future__ import print_function
from __future__ import absolute_import
import ConfigParser
import datetime
import threading
import time

from slackclient import SlackClient
from .responses import bot

Config = ConfigParser.ConfigParser()
Config.read("credentials.ini")

token = Config.get('Slack_Creds', 'token')
print("token: " + token)
sc = SlackClient(token)
robot = bot(sc, token)

print("Starting up!")
connected = False
start = time.time()

# Spin and try to connect every 5 seconds upon initial boot.
while connected is False:
    if sc.rtm_connect():
        print("Successfully connected to Slack!")
        connected = True

        while connected:
            # Read from the Slack Channels that the bot is currently a part of.
            try:
                Incoming_Message = sc.rtm_read()
            except Exception as e:
                print(e)
                Incoming_Message = []
                connected = False

            # Process each incoming message from Slack.
            for msg in Incoming_Message:
                thread = threading.Thread(
                    target=robot.Process, args=(msg,))
                thread.start()

            time.sleep(0.1)
    else:
        print("Connection Failed, invalid token?")
        connected = False
        time.sleep(5)