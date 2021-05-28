from django.db.models.signals import post_save, pre_delete, m2m_changed
from .models import (
    Profile, 
    ChatMessage, 
    FriendRequest, 
    Story,
    StoryNotification,
    StoryComment
    )
from django.conf import settings
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from channels.db import database_sync_to_async
from django.utils import timezone

User = get_user_model()

# Signal to create a profile when a user object is created


@receiver(post_save, sender=User)
def create_profile(sender, instance, created, **kwargs):
    if created:
        profile = Profile.objects.create(user=instance)
        profile.save()


@receiver(post_save, sender=FriendRequest)
def send_request(sender, instance, created, **kwargs):
    if created:
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
    if created:
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

@receiver(m2m_changed,sender=Story.views.through)
def story_viewed(sender, instance, **kwargs):
    if(kwargs['action']=='post_add'):
        print('post add')
        channel_layer = get_channel_layer()
        user_id = kwargs['pk_set'].pop()
        user = User.objects.get(id=user_id)
        time = timezone.now().strftime("%Y-%m-%d %H:%M:%S")
        notif = StoryNotification(notif_type="story_view",to_user=instance.user,from_user=user,story=instance,time_created=time)
        notif.save()
        if instance.user.profile.online:
            _dict = {
                'type':'story_view',
                'u':user.username,
                'id':instance.id,
                'n_id':notif.id,
                'time':time
            }
            async_to_sync(channel_layer.group_send)(instance.user.username,_dict)
    
    # pass

@receiver(post_save,sender=StoryComment)
def story_comment(sender, instance, **kwargs):
    if(kwargs['created']==True):
        channel_layer = get_channel_layer()
        story = instance.story
        user = story.user
        time = timezone.now().strftime("%Y-%m-%d %H:%M:%S") 
        if instance.story.user.profile.online:
            _dict = {
                'type':'story_comment',
                'u':instance.username,
                'comment':instance.comment,
                'c_id':instance.id,
                's_id':instance.story.id,
                'time':time
            }
            async_to_sync(channel_layer.group_send)(user.username,_dict)

@receiver(pre_delete, sender=Story)
def story_deleted_notif(sender, instance, **kwargs):
    friends_qs = instance.user.profile.friends.all()
    channel_layer = get_channel_layer()
    test=[]
    for user in friends_qs:
        notification = StoryNotification.objects.create(storyId=instance.id,notif_type="story_delete",to_user=user,from_user=instance.user)
        notification.save()
        if user.profile.online:
            print(user.username)
            _dict = {
                'type':'story_delete',
                'u':instance.user.username,
                's_id':instance.id,
                'n_id':notification.id,
            }
            test.append(_dict)
            async_to_sync(channel_layer.group_send)(user.username,_dict)
    print(test)