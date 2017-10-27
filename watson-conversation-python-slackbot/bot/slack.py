import json

def get_channel_name(sc, channel_id):
    name = ""
    print "Trying to retrieve name for channel: " + channel_id
    channel_id = str(channel_id)
    channel_info = sc.api_call('channels.info', channel=channel_id)

    if channel_info["ok"] is False:
        channel_info = sc.api_call('groups.info', channel=channel_id)
        name = channel_info["group"]["name"]
    else:
        name = channel_info["channel"]["name"]

    try:
        return name
    except Exception as e:
        print e
        return ""


def get_my_id(sc, my_name):
    api_call = sc.api_call('users.list')
    if api_call.get('ok'):
        print "api call ok"
        print "my name: " + my_name
        # retrieve all users so we can find our bot
        users = api_call.get('members')
        for user in users:
            if 'name' in user and user.get('name') == my_name:
                print("Bot ID for '" + user['name'] + "' is " + user.get('id'))
                return user.get('id')
    else:
        print("could not find bot user with the name " + my_name)


def get_users_name(sc, user_id):
    user_info = sc.api_call('users.info', user=user_id)
    if user_info["ok"] is True:
        return user_info["user"]["name"]
    else:
        return ''
