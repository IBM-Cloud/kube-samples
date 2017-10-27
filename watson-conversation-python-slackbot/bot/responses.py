import ConfigParser
import json
import slack
import sys
from watson_developer_cloud import ConversationV1

class bot(object):

    def __init__(self, sc, token):
        Config = ConfigParser.ConfigParser()
        Config.read("credentials.ini")
        self.name = Config.get('Slack_Creds', 'name')
        self.sc = sc
        self.messages_processed = 0
        self.slack_token = token
        self.me = self.name
        print slack.get_my_id(self.sc, self.me)
        self.at_bot = "<@" + slack.get_my_id(self.sc, self.me) + ">"
        print "AT " + self.name + ": " + self.at_bot
        self.whitelist = [self.name + "-private"]
         # set up conversation service
        self.conversation = ConversationV1(
            username= Config.get('Conversation_Creds', 'username'),
            password= Config.get('Conversation_Creds', 'password'),
            version= Config.get('Conversation_Creds', 'version'))
        self.conversation_workspace_id = Config.get('Conversation_Creds', 'workspace_id')

    def Process(self, msg):
        try:
            if "type" in msg:
                if "subtype" in msg and msg["subtype"] == "group_join" and msg["type"] == "message":
                    print "-- " + self.name + " joined a new group!"
                elif "subtype" in msg and msg["subtype"] == "channel_join" and msg["type"] == "message":
                    print "-- " + self.name + " joined a new channel!"
                elif "subtype" in msg and msg["subtype"] == "message_changed" and msg["type"] == "message":
                    print "-- " + self.name + " detected a changed message in one of her channels."
                elif "subtype" in msg and msg["subtype"] == "bot_message" and msg["type"] == "message":
                    print "-- " + self.name + " detected a new bot-message.. ignoring!"
                elif msg["type"] == "message" and (self.at_bot in msg["text"] or "@here" in msg["text"]):
                    self.messages_processed += 1
                    print msg["text"]
                    response = self.conversation.message(
                                                workspace_id=self.conversation_workspace_id, 
                                                message_input={'text': msg["text"]})
                    print json.dumps(response['output'])
                    if len(response['output']['text']) > 0:
                        if 'function' in response['output']:
                            if response['output']['function'] != 'trains_status':
                                self.sc.rtm_send_message(msg["channel"], response['output']['text'][0])
                        else:
                            self.sc.rtm_send_message(msg["channel"], response['output']['text'][0])
                        print(response['output']['text'][0])
                        if 'function' in response['output']:
                            self.call_response(response['output'], msg)
                    else:
                        self.sc.rtm_send_message(msg["channel"], "It looks like I don't have an answer.. Watson isn't here right now\n:boom:")
                        print('no response from watson conversation')
                    
                elif msg["type"] == "message" and "<@" in msg["text"]:
                    print("Found a message to another person...")

        except Exception as e:
            print("error:")
            print(msg)
            print(e)
            print("\n\n")
