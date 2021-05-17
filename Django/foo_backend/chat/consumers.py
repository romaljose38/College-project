import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .models import (
    Thread,
    Profile,
    ChatMessage,
    FriendRequest,
    Notification,
    StoryNotification
)
from django.utils import timezone
from django.contrib.auth import get_user_model
from datetime import datetime

User = get_user_model()

# Right now we need two chat consumers.
# One to be used in production and the other one in development for testing and debugging.
# The primary difference between the two is that the latter does require authentication. 



# Consumers are written in such a way that the component functions are arranged in the order in which
# they are triggered. 
# ie 'connect' -> 'receive' -> 'chat_message' -> 'disconnect'
# The database operations performed by each function are given next to it. For the sake of comprehension and readability.


# ===========================================
# Consumer; strictly for use in production
# ===========================================
class DevelopmentChatConsumer(AsyncWebsocketConsumer):

    room_group_name = "chat_room"

    async def connect(self):

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()
        

    async def receive(self,text_data):
        
        print("In receive" , text_data)
        json_data = json.loads(text_data)
        
        # Sending to all users in the group/room
        await self.channel_layer.group_send(
            self.room_group_name,{    
            'type':'chat_message',
            'message':json_data
        })

    async def chat_message(self,event):
        
        print("In chat_message", event)
        event['message']['time'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Converting the json object to a string
        message = json.dumps({                  
            'message':event['message']
        })

        # Sending to the connected user
        await self.send(text_data = message)

    async def disconnect(self,close_code):
        
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )



# =====================================
# Consumer: For production
# =====================================

class ChatConsumer(AsyncWebsocketConsumer):


    async def connect(self):        

        username = self.scope['url_route']['kwargs']['username']
        self.room_group_name = username
        self.user = await self.get_user_from_username(username)
        print(self.user.username)
        status = await self.update_user_online(self.user)
        self.recent_chat_with = ""
        if status:
        
            

            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )

            await self.accept()
            
            pending_messages = await self.get_pending_messages()
            pending_msg_status = await self.get_pending_notifications()
            # pending_requests = await self.get_pending_requests()
            pending_story_notifs = await self.get_pending_story_notifications()

            if len(pending_messages)>0:
                for msg in pending_messages:
                    text,snd_user,chat_id = await self.get_chat_details(msg)
                    
                    msg_obj = json.dumps({
                        'message':{
                        'message':text,
                        'from':snd_user,
                        'id':chat_id,                     
                    }})

                    await self.send(text_data=msg_obj)
            if len(pending_msg_status)>0:
                for msg in pending_msg_status:
                    await self.send(text_data=json.dumps(msg))

            if len(pending_story_notifs)>0:
                for msg in pending_story_notifs:
                    await self.send(text_data=json.dumps(msg))
            # if len(pending_requests)>0:
            #     for req in pending_requests:
            #         request = await self.get_request_details(req)
                    
            #         msg_obj = json.dumps(request)

            #         await self.send(text_data=msg_obj)
                    

    @database_sync_to_async
    def update_user_online(self, user):
        if self.user.profile.online:
            return False
        else: 
            Profile.objects.filter(user=user).update(online=True)
            return True

    @database_sync_to_async
    def get_pending_messages(self):

        threads = []
        # Get all the threads in which the user is a member
        for thread in Thread.objects.all():
            if self.user == thread.first or self.user == thread.second:
                threads.append(thread)

        chat_messages = []
        # Checking each thread for unread chat messages for user and appending those to the corresponding list
        if len(threads)!=0:
            for thread in threads:
                for chat in thread.chatmessage_set.all():
                    if self.user not in chat.recipients.all():
                        chat_messages.append(chat)

        return chat_messages


    @database_sync_to_async
    def get_chat_details(self, chat_message):
        return chat_message.message, chat_message.user.username, chat_message.id

    @database_sync_to_async
    def get_pending_requests(self):
        return FriendRequest.objects.filter(to_user=self.user, has_received=False)

    @database_sync_to_async
    def get_pending_notifications(self):
        final_list = []
        qs = Notification.objects.filter(notif_to=self.user)
        print(qs,"queryset")
        for i in qs:
            if i.notif_type=="received":
                final_list.append({                        
                            'received':i.chatmsg_id,
                            'from':i.notif_from.username,
                            'notif_id':i.id,
                        },
                )
            elif i.notif_type=="seen":
                final_list.append({                        
                            'type':"seen_ticker",
                            'from':i.notif_from.username,
                            'id':i.chatmsg_id,
                            'notif_id':i.id,
                        }
                )

        print(final_list)
        return final_list

    @database_sync_to_async
    def get_pending_story_notifications(self):
        final_list = []
        qs = StoryNotification.objects.filter(to_user=self.user)
        print(qs,"queryset")
        for notif in qs:
            if notif.notif_type=="story_add":
                final_list.append({                        
                            'type':'story_add',
                            'u':notif.story.user.username,
                            'u_id':notif.story.user.id,
                            's_id':notif.story.id,
                            'url':notif.story.file.url,
                            'n_id':notif.id,
                            'time':notif.story.time_created.strftime("%Y-%m-%d %H:%M:%S"),
                        },
                )
           

        print(final_list)
        # return final_list

    @database_sync_to_async
    def get_request_details(self, request):
        return {"type":"notification","username":request.from_user.username, "user_id":request.from_user.id, "id":request.id}

    async def receive(self, text_data):
        print(text_data)
        text_data_json = json.loads(text_data)
        if 'received' in text_data_json:
            print(text_data_json)
            # pass
            msg_id = int(text_data_json['received'])
            should_inform, chat_id ,chat_user, id = await self.add_user_to_recipients(msg_id)
            if should_inform:
                await self.channel_layer.group_send(
                                                    chat_user.username,
                                                    {
                                                        'type':'chat_received_notif',
                                                        'message':{                                                            
                                                            'received':chat_id,
                                                            'from':self.user.username,
                                                            'notif_id':id
                                                        }
                                                    }
                                                )
        elif 'n_r' in text_data_json:
            await self.delete_notification(text_data_json['n_r'])
        elif 's_r' in text_data_json:
            await self.delete_story_notification(text_data_json['s_r'])
        else:
            if text_data_json['type']=="seen_ticker":
                print(text_data_json)
                to_user, status = await self.get_user_status_from_username(text_data_json['to'])
                notif_id = await self.create_notification_from_json(text_data_json,to_user)
                text_data_json['notif_id']=notif_id
                if status:
                    await self.channel_layer.group_send(
                        text_data_json['to'],
                        text_data_json
                    )
                
                    
            elif text_data_json['type']=='typing_status':
                text_data_json['from'] = self.room_group_name
                to = text_data_json['to']
                self.recent_chat_with  = to
                text_data_json.pop("to")
                await self.channel_layer.group_send(
                        to,
                        text_data_json
                    )
                
            else:
                to = text_data_json['to']
                time_str = text_data_json['time']
                _id = text_data_json['id']
                if(text_data_json['type']=='msg'):           # This is the username of the user to which the message is to be sent
                    msg = text_data_json['message']

                    chat_msg_id = await self.create_chat_message(message=msg,to=to,time=time_str)
                
                    message = {
                        'message':msg,
                        'to':to,
                        'id':chat_msg_id,
                        'time':time_str,
                        'from':self.user.username  # This line is not needed in production; only for debugging
                    }

                    await self.send(text_data=json.dumps(
                        {
                        "r_s":{
                            'to':to,
                            'id':_id,
                            'n_id':chat_msg_id,
                        }
                        }
                        )
                    )
                    await self.channel_layer.group_send(
                    to,
                    {
                        'type':'chat_message',
                        'message': message
                    }
                    )

                elif(text_data_json['type']=='aud'):
                    aud = text_data_json['audio']
                    extension = text_data_json['ext']

                    chat_msg_id = await self.create_chat_audio(aud_string=aud, to=to, ext=extension, time=time_str)
                    
                    message = {
                        'aud':aud,
                        'ext':extension,
                        'to':to,
                        'time':time_str,
                        'id':chat_msg_id,
                        'from':self.user.username  # This line is not needed in production; only for debugging
                    }
                    await self.send(text_data=json.dumps(
                        {
                        "r_s":{
                            'to':to,
                            'id':_id,
                            'n_id':chat_msg_id,
                        }
                        }
                        )
                    )

                    await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type':'chat_message',
                        'message': message
                    }
                    )

                elif(text_data_json['type']=='img'):
                    img = text_data_json['image']
                    extension = text_data_json['ext']

                    chat_msg_id = await self.create_chat_image(img_string=img,to=to,ext=extension, time=time_str)
            
                    message = {
                        'img':img,
                        'ext':extension,
                        'time':time_str,
                        'to':to,
                        'id':chat_msg_id,
                        'from':self.user.username  # This line is not needed in production; only for debugging
                    }

                    await self.send(text_data=json.dumps(
                        {
                        "r_s":{
                            'to':to,
                            'id':_id,
                            'n_id':chat_msg_id,
                        }
                        }
                        )
                    )

                    await self.channel_layer.group_send(
                        to,
                        {
                            'type':'chat_message',
                            'message': message
                        }
                    )


    @database_sync_to_async
    def add_user_to_recipients(self,msg_id):
        chat_msg = ChatMessage.objects.get(id=msg_id)
        chat_msg.recipients.add(self.user)
        chat_msg.save()
        if (self.user != chat_msg.user):
            notification = Notification(notif_type="received", notif_from=self.user, notif_to=chat_msg.user, chatmsg_id=chat_msg.id)
            notification.save()
            if chat_msg.user.profile.online:
                return True, chat_msg.id ,chat_msg.user, notification.id
 
            return False, None, None, None
        return False, None, None, None
       



    @database_sync_to_async
    def create_chat_message(self, message, to, time):
        thread = Thread.objects.get_or_new(self.user,to)
        cur_message = ChatMessage.objects.create(user=self.user, message=message, thread=thread, msg_type="msg",time_created=time)
        cur_message.recipients.add(self.user)
        cur_message.save()
        return cur_message.id


    @database_sync_to_async
    def create_chat_audio(self, aud_string, to, ext, time):
        thread = Thread.objects.get_or_new(self.user,to)
        cur_message = ChatMessage.objects.create(user=self.user, base64string=aud_string, thread=thread, msg_type="aud", extension=ext, time_created=time)
        cur_message.recipients.add(self.user)
        cur_message.save()
        return cur_message.id


    @database_sync_to_async
    def create_chat_image(self, img_string, to, ext, time):
        thread = Thread.objects.get_or_new(self.user,to)
        cur_message = ChatMessage.objects.create(user=self.user, base64string=img_string, thread=thread, msg_type="img", extension=ext,time_created=time)
        cur_message.recipients.add(self.user)
        cur_message.save()
        return cur_message.id

    @database_sync_to_async
    def get_user_status_from_username(self, username):
        user = User.objects.get(username=username)
        return user, user.profile.online
    
    @database_sync_to_async
    def create_notification_from_json(self, obj, to_user):
        notification = Notification(chatmsg_id=obj['id'],notif_from=self.user,notif_to=to_user,notif_type="seen")
        notification.save()
        return notification.id

    @database_sync_to_async
    def delete_notification(self, id):
        notif = Notification.objects.get(id=id)
        notif.delete()

    @database_sync_to_async
    def delete_story_notification(self, id):
        notif = StoryNotification.objects.get(id=id)
        notif.delete()



    async def chat_message(self,event):
        print(event)
        print("room group name",self.room_group_name)

        if 'aud' in event['message']:
            event['msg_type']='aud'
        elif 'img' in event['message']:
            event['msg_type']='img'
        elif 'message' in event['message']:
            event['msg_type']='txt'
        # to_username = event['message']['to']
        # from_username = event['message']['from']

        # to_user_obj = await self.get_user_from_username(to_username)
        # from_user_obj = await self.get_user_from_username(from_username)

        # print(event)
        
        # if self.user == to_user_obj or self.user == from_user_obj:
        #     print(to_user_obj.username,from_user_obj.username)
        json_data = json.dumps(event)
        await self.send(text_data=json_data)

    async def notification(self,event):
        print(event)
        await self.send(text_data=json.dumps(event))

    @database_sync_to_async
    def get_user_from_username(self, username):
        return User.objects.get(username=username)

    async def disconnect(self, close_code):
        if self.recent_chat_with != "":
            data =  {'from':self.room_group_name,
                    'type': 'typing_status',
                    'status': 'stopped',}
            print(self.recent_chat_with)
            await self.channel_layer.group_send(
                self.recent_chat_with,
                data
                )
        
        await self.update_user_offline(self.user)
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    @database_sync_to_async
    def update_user_offline(self, user):
        Profile.objects.filter(user=user).update(online=False,last_seen=timezone.now())

    
    async def seen_ticker(self,event):
        print(event)
        await self.send(text_data=json.dumps(event))


    async def chat_received_notif(self,event):
        json_data = json.dumps({'received':event['message']['received'],
                                'from':event['message']['from'],
                                'notif_id':event['message']['notif_id']})
        await self.send(text_data=json_data)


    async def typing_status(self,event):
        print("reached here")
        await self.send(text_data=json.dumps(event))

    async def story_add(self,event):
        print(event)
        print(self.room_group_name)
        await self.send(text_data=json.dumps(event))