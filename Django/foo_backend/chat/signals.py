from django.db.models.signals import post_save, m2m_changed
from .models import (
    Profile, 
    ChatMessage, 
    FriendRequest, 
    Story,
    StoryNotification,
    )
from django.conf import settings
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from channels.db import database_sync_to_async


User = get_user_model()

# Signal to create a profile when a user object is created


@receiver(post_save, sender=User)
def create_profile(sender, instance, created, **kwargs):
    if created:
        profile = Profile.objects.create(user=instance)
        profile.save()


@receiver(post_save, sender=FriendRequest)
def send_request(sender, instance, created, **kwargs):
    if instance.status == "pending":
        channel_layer = get_channel_layer()
        print(channel_layer)
        if instance.to_user.profile.online:
            print("hes online")
            # send_notif(instance.to_user.username)
            async_to_sync(channel_layer.group_send)(instance.to_user.username, {
                "type": "notification", 
                "username": instance.from_user.username, 
                'user_id': instance.from_user.id, 
                'id': instance.id
                })


@receiver(post_save, sender=Story)
def story_created_notif(sender, instance, created, **kwargs):
    friends_qs = instance.user.profile.friends.all()
    channel_layer = get_channel_layer()
    test=[]
    for user in friends_qs:
        notification = StoryNotification.objects.create(story=instance,notif_type="story_add",to_user=user)
        notification.save()
        if user.profile.online:
            print(user.username)
            _dict = {
                'type':'story_add',
                'u':instance.user.username,
                'u_id':instance.user.id,
                's_id':instance.id,
                'url':instance.file.url,
                'n_id':notification.id,
                'time':instance.time_created.strftime("%Y-%m-%d %H:%M:%S"),
            }
            test.append(_dict)
            async_to_sync(channel_layer.group_send)(user.username,_dict)
    print(test)



    
# @database_sync_to_async
# def get_user_status(user):
#     return user.profile.online

# @database_sync_to_async
# def get_user_from_id(id):
#     return


async def send_notif(from_username):

    message = {
        # 'to':user.username,
        'message': "request",
        # 'from':from_username,
    }

    await channel_layer.group_send(
        from_username,
        {"type": "chat_message", "message": message},
    )
    print("in here")


# def inform_user(sender, instance, pk_set, **kwargs):
#     print(instance.user, pk_set)
#     id=list(pk_set)[0]
#     user = User.objects.get(id=id)
#     if user!=instance.user:
#         async_to_sync(send_notif)(instance.user,id,user.username)


# m2m_changed.connect(inform_user,sender=ChatMessage.recipients.through)
