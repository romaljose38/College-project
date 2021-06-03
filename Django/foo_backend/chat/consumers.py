import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.generic.http import AsyncHttpConsumer
from channels.db import database_sync_to_async
from .models import (
    Story,
    Thread,
    Profile,
    ChatMessage,
    FriendRequest,
    Notification,
    StoryNotification,
    StoryComment,
    MentionNotification,
)
from django.utils import timezone
from django.contrib.auth import get_user_model
from datetime import datetime
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
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
            informing_list = await self.inform_people()
            await self.send_pending_messages()
            # print(tes)
            pending_msg_status = await self.get_pending_notifications()
            pending_requests = await self.get_pending_requests()
            pending_story_notifs = await self.get_pending_story_notifications()
            pending_story_comment_notifs = await self.get_pending_story_comment_notification()
            pending_mentions = await self.get_mentions()

            
            if len(informing_list)>0:
                for msg in informing_list:
                    await self.channel_layer.group_send(
                        msg[0],
                        msg[1]
                    )
            
            if len(pending_msg_status)>0:
                for msg in pending_msg_status:
                    await self.send(text_data=json.dumps(msg))

            if len(pending_mentions)>0:
                for msg in pending_mentions:
                    await self.send(text_data=json.dumps(msg))


            if len(pending_story_notifs)>0:
                for msg in pending_story_notifs:
                    await self.send(text_data=json.dumps(msg))

            if len(pending_story_comment_notifs)>0:
                for msg in pending_story_comment_notifs:
                    await self.send(text_data=json.dumps(msg))

            if len(pending_requests)>0:
                for req in pending_requests:                    
                    msg_obj = json.dumps(req)

                    await self.send(text_data=msg_obj)
                    
    @database_sync_to_async
    def inform_people(self):
        final_list =[]
        online_inform_qs = self.user.profile.people_i_should_inform.all()
        for user in online_inform_qs:
            if user.profile.online:
                final_list.append([
                    user.username,
                    {   
                        'type':'online_status',
                        'u':self.user.username,
                        's':'online'
                    }
                ])
        return final_list
    

    async def send_pending_messages(self):
        pending_messages = await self.get_pending_messages()
        if len(pending_messages)>0:
                for msg in pending_messages:
                    text,snd_user,chat_id,time = await self.get_chat_details(msg)
                    
                    msg_obj = json.dumps({
                        'message':{
                        'message':text,
                        'from':snd_user,
                        'time':time,
                        'id':chat_id,                     
                    },
                    'msg_type':'txt',
                    'type':'chat_message'})
                    
                    await self.send(text_data=msg_obj)



    @database_sync_to_async
    def update_user_online(self, user):
        if self.user.profile.online:
            return False
        else: 
            Profile.objects.filter(user=user).update(online=True)
            return True

    @database_sync_to_async
    def get_mentions(self):
        final_list = []
        mentions_qs = MentionNotification.objects.filter(to_user=self.user)

        for mention in mentions_qs:
            final_list.append({
                'type':'mention_notif',
                'u':mention.from_user.username,
                'id':mention.post_id,
                'n_id':mention.id,
                'time':mention.time_created,
                'dp':mention.from_user.profile.profile_pic.url,
            })
        
        return final_list


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
        return chat_message.message, chat_message.user.username, chat_message.id, chat_message.time_created

    @database_sync_to_async
    def get_pending_requests(self):
        request_qs = FriendRequest.objects.filter(to_user=self.user, has_received=False)

        requests = []

        for request in request_qs:
            requests.append({"type":"notification","username":request.from_user.username, "user_id":request.from_user.id, "id":request.id, 'time':request.time_created,'dp':request.from_user.profile.profile_pic.url})

        return requests

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
            elif i.notif_type=="s_reached":
                final_list.append({                        
                            'r_s':{
                                'to':i.chat_username,
                                'notif_id':i.id,
                                'id':int(i.ref_id),
                                'n_id':i.chatmsg_id,
        
                            },
                            
                        }
                )
            elif i.notif_type=="delete":
                final_list.append({
                    'type':'chat_delete',
                    'from':i.notif_from.username,
                    'id':i.chatmsg_id,
                    'notif_id':i.id,
                })

            elif i.notif_type=="dp_notif":
                final_list.append({
                    'type':'dp_update',
                    'id':int(i.ref_id),
                    'n_id':i.id
                })

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
                            'dp':notif.story.user.profile.profile_pic.url if notif.story.user.profile.profile_pic else '',
                            'url':notif.story.file.url,
                            'caption':notif.story.caption,
                            'n_id':notif.id,
                            'time':notif.story.time_created.strftime("%Y-%m-%d %H:%M:%S"),
                        },
                )
            elif notif.notif_type=="story_view":
                final_list.append({                        
                            'type':'story_view',
                            'u':notif.from_user.username, 
                            'id':notif.story.id,
                            'dp':notif.from_user.profile.profile_pic.url if notif.from_user.profile.profile_pic else '',                          
                            'n_id':notif.id,
                            'time':notif.time_created,
                        },
                )
            elif notif.notif_type=="story_delete":
                final_list.append({
                    'type':'story_delete',
                    'u_id':notif.from_user.id,
                    's_id':notif.storyId,
                    'n_id':notif.id,
                    },
                )
           

        print(final_list)
        return final_list

    @database_sync_to_async
    def get_pending_story_comment_notification(self):
        final_list = []
        qs = Story.objects.filter(user=self.user)
        for story in qs:
            for comment in story.story_comment.all():
                final_list.append({
                    'type':'story_comment', #For the client to identify
                    'u':comment.user.username,
                    'comment':comment.comment,
                    'c_id':comment.id,
                    'dp':comment.user.profile.profile_pic.url if comment.user.profile.profile_pic else '',
                    's_id':story.id,
                    'time':comment.time_created.strftime("%Y-%m-%d %H:%M:%S"),
                },
            )

        print(final_list)
        return final_list

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
        elif 'm_r' in text_data_json:
            await self.delete_mention_notification(text_data_json['m_r'])
        elif 'f_r' in text_data_json:
            await self.receive_friend_request(text_data_json['f_r'])
        elif 's_r' in text_data_json:
            await self.delete_story_notification(text_data_json['s_r'])
        elif 's_n_r' in text_data_json:
            await self.delete_story_comment_notification(text_data_json['s_n_r'])
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
            elif text_data_json['type'] == "chat_delete":
                text_data_json['from'] = self.room_group_name
                to = text_data_json['to']
                text_data_json.pop('to')
                await self.create_chat_delete_notif(to,text_data_json['id'])
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

                    chat_msg_id,notif_id = await self.create_chat_message(message=msg,to=to,time=time_str,ref_id=_id)
                
                    message = {
                        'message':msg,                        
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
                            'notif_id':notif_id,
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
                
                elif(text_data_json['type']=='reply_txt'):           # This is the username of the user to which the message is to be sent
                    msg = text_data_json['message']

                    chat_msg_id,notif_id = await self.create_chat_message(message=msg,to=to,time=time_str,ref_id=_id)
                
                    message = {
                        'message':msg,                        
                        'id':chat_msg_id,
                        'time':time_str,
                        'reply_txt':text_data_json['reply_txt'],
                        'reply_id':text_data_json['reply_id'],
                        'from':self.user.username  # This line is not needed in production; only for debugging
                    }

                    await self.send(text_data=json.dumps(
                        {
                        "r_s":{
                            'to':to,
                            'id':_id,
                            'n_id':chat_msg_id,
                            'notif_id':notif_id,
                        }
                        }
                        )
                    )
                    await self.channel_layer.group_send(
                    to,
                    {
                        'type':'chat_reply_message',
                        'message': message,
                        'msg_type':'reply_txt'
                    }
                    )
                
                
                # elif(text_data_json['type']=='aud'):
                #     aud = text_data_json['audio']
                #     extension = text_data_json['ext']

                #     chat_msg_id = await self.create_chat_audio(aud_string=aud, to=to, ext=extension, time=time_str)
                    
                #     message = {
                #         'aud':aud,
                #         'ext':extension,
                        
                #         'time':time_str,
                #         'id':chat_msg_id,
                #         'from':self.user.username  # This line is not needed in production; only for debugging
                #     }
                #     await self.send(text_data=json.dumps(
                #         {
                #         "r_s":{
                #             'to':to,
                #             'id':_id,
                #             'n_id':chat_msg_id,
                #         }
                #         }
                #         )
                #     )

                #     await self.channel_layer.group_send(
                #     self.room_group_name,
                #     {
                #         'type':'chat_message',
                #         'message': message
                #     }
                #     )

                # elif(text_data_json['type']=='img'):
                #     img = text_data_json['image']
                #     extension = text_data_json['ext']

                #     chat_msg_id = await self.create_chat_image(img_string=img,to=to,ext=extension, time=time_str)
            
                #     message = {
                #         'img':img,
                #         'ext':extension,
                #         'time':time_str,                        
                #         'id':chat_msg_id,
                #         'from':self.user.username  # This line is not needed in production; only for debugging
                #     }

                #     await self.send(text_data=json.dumps(
                #         {
                #         "r_s":{
                #             'to':to,
                #             'id':_id,
                #             'n_id':chat_msg_id,
                #         }
                #         }
                #         )
                #     )

                #     await self.channel_layer.group_send(
                #         to,
                #         {
                #             'type':'chat_message',
                #             'message': message
                #         }
                #     )


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
    def create_chat_delete_notif(self,to,id):
        user = User.objects.get(username=to)
        notification = Notification(chatmsg_id=int(id),notif_from=self.user,notif_to=user,notif_type="delete")
        



    @database_sync_to_async
    def create_chat_reply_message(self, message, to, time, ref_id, reply_txt, reply_id):
        thread = Thread.objects.get_or_new(self.user,to)
        cur_message = ChatMessage.objects.create(reply_id=reply_id,reply_txt=reply_txt,user=self.user, message=message, thread=thread, msg_type="msg",time_created=time)
        cur_message.recipients.add(self.user)
        cur_message.save()
        notif = Notification(notif_to=self.user,chatmsg_id=cur_message.id,ref_id=str(ref_id), notif_type="s_reached")
        notif.save()
        return cur_message.id, notif.id

    @database_sync_to_async
    def create_chat_message(self, message, to, time, ref_id):
        thread = Thread.objects.get_or_new(self.user,to)
        cur_message = ChatMessage.objects.create(user=self.user, message=message, thread=thread, msg_type="msg",time_created=time)
        cur_message.recipients.add(self.user)
        cur_message.save()
        notif = Notification(notif_to=self.user,chatmsg_id=cur_message.id,ref_id=str(ref_id), notif_type="s_reached")
        notif.save()
        return cur_message.id, notif.id


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
        try:
            notif = Notification.objects.get(id=id)
            notif.delete()
        except Exception as e:
            print(e)

    @database_sync_to_async
    def delete_story_notification(self, id):
        try:
            notif = StoryNotification.objects.get(id=id)
            notif.delete()
        except Exception as e:
            print(e)

    @database_sync_to_async
    def receive_friend_request(self, id):
        try:
            notif = FriendRequest.objects.get(id=id)
            notif.has_received = True
            notif.save()
        except Exception as e:
            print(e)

    @database_sync_to_async
    def delete_mention_notification(self, id):
        try:
            notif = MentionNotification.objects.get(id=id)
            notif.delete()
        except Exception as e:
            print(e)

    @database_sync_to_async
    def delete_story_comment_notification(self, id):
        try:
            comment = StoryComment.objects.get(id=id)
            comment.delete()
        except Exception as e:
            print(e)

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


    async def chat_delete(self,event):
        await self.send(text_data=json.dumps(event))


    async def notification(self,event):
        print(event)
        await self.send(text_data=json.dumps(event))

    @database_sync_to_async
    def get_user_from_username(self, username):
        return User.objects.get(username=username)

    async def disconnect(self, close_code):

        await self.get_informers_list()
        # print(informing_list)
        await self.remove_me_from_others_lists()
        
        
        

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
        # if len(informing_list)>0:
        #         for msg in informing_list:
        #             await self.channel_layer.group_send(
        #                 msg[0],
        #                 msg[1]
        #             )
        

    @database_sync_to_async
    def remove_me_from_others_lists(self):
        qs = self.user.profile.people_i_peek.all()
        for user in qs:
            user.profile.people_i_should_inform.remove(self.user)
    
        



    @database_sync_to_async
    def get_informers_list(self):
        final_list =[]
        offline_inform_qs = self.user.profile.people_i_should_inform.all()
        for user in offline_inform_qs:
            # if user.profile.online:
                # final_list.append([
                # user.username,
                _dict= {   
                        'type':'online_status',
                        'u':self.user.username,
                        's':'offline'
                    }
                # ])
                async_to_sync(self.channel_layer.group_send)(user.username,_dict)
        # return final_list

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

    async def story_delete(self,event):
        print(event)
        print(self.room_group_name)
        await self.send(text_data=json.dumps(event))

    async def online_status(self,event):
        print(event)
        print(self.room_group_name)
        await self.send(text_data=json.dumps(event))


    async def story_view(self,event):
        print(event)
        print(self.room_group_name)
        await self.send(text_data=json.dumps(event))

    async def story_comment(self,event):
        print(event)
        print(self.room_group_name)
        await self.send(text_data=json.dumps(event))

    async def server_response(self,event):
        print(event)
        event.pop("type")
        print(self.room_group_name)
        await self.send(text_data=json.dumps(event))

    async def chat_reply_message(self, event):
        
        await self.send(text_data=json.dumps(event))

    async def mention_notif(self, event):
        await self.send(text_data=json.dumps(event))

    async def dp_update(self, event):
        await self.send(text_data=json.dumps(event))