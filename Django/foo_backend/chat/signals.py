from django.db.models.signals import post_save, pre_delete, m2m_changed
from .models import (
    Profile, 
    ChatMessage, 
    FriendRequest,
    Notification,
    Story,
    StoryNotification,
    StoryComment,
    Comment,
    MentionNotification
    )
from django.conf import settings
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from channels.db import database_sync_to_async
from django.utils import timezone
from foo_backend.celery import app
# from .signal_registry import profile

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
        send_request_celery.delay(instance.id)
        # if instance.status == "pending":
        #     channel_layer = get_channel_layer()
        #     print(channel_layer)
        #     if instance.to_user.profile.online:
        #         print("hes online")
        #         # send_notif(instance.to_user.username)
        #         async_to_sync(channel_layer.group_send)(instance.to_user.username, {
        #             "type": "notification", 
        #             "username": instance.from_user.username, 
        #             'user_id': instance.from_user.id, 
        #             'dp':instance.from_user.profile.profile_pic.url,
        #             'id': instance.id,
        #             'time':instance.time_created,
  #             })

@app.task()      
def send_request_celery(id):
    instance = FriendRequest.objects.get(id=id)
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
                    'dp':instance.from_user.profile.profile_pic.url,
                    'id': instance.id,
                    'time':instance.time_created,
                    })

@receiver(post_save, sender=Story)
def story_created_notif(sender, instance, created, **kwargs):
    if created:
        story_created_notif_celery.delay(instance.id)
        # friends_qs = instance.user.profile.friends.all()
        # channel_layer = get_channel_layer()
        # test=[]
        # for user in friends_qs:
        #     notification = StoryNotification.objects.create(story=instance,notif_type="story_add",to_user=user)
        #     notification.save()
        #     if user.profile.online:
        #         print(user.username)
        #         _dict = {
        #             'type':'story_add',
        #             'u':instance.user.username,
        #             'u_id':instance.user.id,
        #             's_id':instance.id,
        #             'url':instance.file.url,
        #             'n_id':notification.id,
        #             'time':instance.time_created.strftime("%Y-%m-%d %H:%M:%S"),
        #         }
        #         test.append(_dict)
        #         async_to_sync(channel_layer.group_send)(user.username,_dict)
        # print(test)



@app.task()
def story_created_notif_celery(id):
        instance = Story.objects.get(id=id)
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
                    'dp':instance.user.profile.profile_pic.url if instance.user.profile.profile_pic else "",
                    's_id':instance.id,
                    'url':instance.file.url,
                    'caption':instance.caption,
                    'n_id':notification.id,
                    'time':instance.time_created.strftime("%Y-%m-%d %H:%M:%S"),
                }
                test.append(_dict)
                async_to_sync(channel_layer.group_send)(user.username,_dict)
        print(test)




@receiver(m2m_changed,sender=Story.views.through)
def story_viewed(sender, instance, **kwargs):
    if(kwargs['action']=='post_add'):
        print('post add')
        # channel_layer = get_channel_layer()
        user_id = kwargs['pk_set'].pop()
        story_viewed_celery.delay(instance.id, user_id)
        # user = User.objects.get(id=user_id)
        # time = timezone.now().strftime("%Y-%m-%d %H:%M:%S")
        # notif = StoryNotification(notif_type="story_view",to_user=instance.user,from_user=user,story=instance,time_created=time)
        # notif.save()
        # if instance.user.profile.online:
        #     _dict = {
        #         'type':'story_view',
        #         'u':user.username,
        #         'id':instance.id,
        #         'n_id':notif.id,
        #         'time':time
        #     }
        #     async_to_sync(channel_layer.group_send)(instance.user.username,_dict)
    
    # pass


@app.task()
def story_viewed_celery(instance_id, id):
        instance = Story.objects.get(id=instance_id)
        channel_layer = get_channel_layer()
        user_id = id
        user = User.objects.get(id=user_id)

        time = timezone.now().strftime("%Y-%m-%d %H:%M:%S")
        notif = StoryNotification(notif_type="story_view",to_user=instance.user,from_user=user,story=instance,time_created=time)
        notif.save()
        if instance.user.profile.online:
            _dict = {
                'type':'story_view',
                'u':user.username,
                'dp':user.profile.profile_pic.url if user.profile.profile_pic else '',
                'id':instance.id,
                'n_id':notif.id,
                'time':time
            }
            async_to_sync(channel_layer.group_send)(instance.user.username,_dict)



@receiver(post_save,sender=StoryComment)
def story_comment(sender, instance, **kwargs):
    if(kwargs['created']==True):
        story_comment_celery.delay(instance.id)
        # channel_layer = get_channel_layer()
        # story = instance.story
        # user = story.user
        # time = timezone.now().strftime("%Y-%m-%d %H:%M:%S") 
        # if instance.story.user.profile.online:
        #     _dict = {
        #         'type':'story_comment',
        #         'u':instance.username,
        #         'comment':instance.comment,
        #         'c_id':instance.id,
        #         's_id':instance.story.id,
        #         'time':time
        #     }
        #     async_to_sync(channel_layer.group_send)(user.username,_dict)

@app.task()
def story_comment_celery(id):
        instance =StoryComment.objects.get(id=id)
        channel_layer = get_channel_layer()
        story = instance.story

        user = story.user
        time = timezone.now().strftime("%Y-%m-%d %H:%M:%S") 
        if instance.story.user.profile.online:
            _dict = {
                'type':'story_comment',
                'u':instance.user.username,
                'dp':instance.user.profile.profile_pic.url if instance.user.profile.profile_pic else '',
                'comment':instance.comment,
                'c_id':instance.id,
                's_id':instance.story.id,
                'time':time
            }
            async_to_sync(channel_layer.group_send)(user.username,_dict)    


@receiver(pre_delete, sender=Story)
def story_deleted_notif(sender, instance, **kwargs):
    story_deleted_notif_celery.delay(instance.user.id,instance.id)
    # friends_qs = instance.user.profile.friends.all()
    # channel_layer = get_channel_layer()
    # test=[]
    # for user in friends_qs:
    #     notification = StoryNotification.objects.create(storyId=instance.id,notif_type="story_delete",to_user=user,from_user=instance.user)
    #     notification.save()
    #     if user.profile.online:
    #         print(user.username)
    #         _dict = {
    #             'type':'story_delete',
    #             'u':instance.user.username,
    #             's_id':instance.id,
    #             'n_id':notification.id,
    #         }
    #         test.append(_dict)
    #         async_to_sync(channel_layer.group_send)(user.username,_dict)
    # print(test)

@app.task()
def story_deleted_notif_celery(user_id,story_id):
        _user = User.objects.get(id=user_id)
        friends_qs = _user.profile.friends.all()
        channel_layer = get_channel_layer()
        test=[]
        for user in friends_qs:
            notification = StoryNotification.objects.create(storyId=story_id,notif_type="story_delete",to_user=user,from_user=_user)
            notification.save()
            if user.profile.online:
                print(user.username)
                _dict = {
                    'type':'story_delete',
                    'u_id':_user.id,
                    's_id':story_id,
                    'n_id':notification.id,
                }
                test.append(_dict)
                async_to_sync(channel_layer.group_send)(user.username,_dict)
        print(test)



@receiver(m2m_changed,sender=Comment.mentions.through)
def comment_mention(sender, instance, **kwargs):
    if(kwargs['action']=='post_add'):
        print('post add')
        # channel_layer = get_channel_layer()

        user_id = kwargs['pk_set'].pop()
        comment_mention_celery.delay(instance.id, user_id)
        # user = User.objects.get(id=user_id)
        # time = timezone.now().strftime("%Y-%m-%d %H:%M:%S")
        # notif = MentionNotification(from_user=instance.user, to_user= user, time_created=time, post_id=instance.post.id)
        # notif.save()
        
        # if user.profile.online:
        #     _dict = {
        #         'type':'mention_notif',
        #         'u':instance.user.username,
        #         'id':instance.post.id,
        #         'n_id':notif.id,
        #         'time':time,
        #         'dp':instance.user.profile.profile_pic.url
        #     }
        #     async_to_sync(channel_layer.group_send)(user.username,_dict)


@app.task()
def comment_mention_celery(instance_id,id):
        instance = User.objects.get(id=instance_id)
        channel_layer = get_channel_layer()

        user_id = id
        user = User.objects.get(id=user_id)
        time = timezone.now().strftime("%Y-%m-%d %H:%M:%S")
        notif = MentionNotification(from_user=instance.user, to_user= user, time_created=time, post_id=instance.post.id)
        notif.save()
        
        if user.profile.online:
            _dict = {
                'type':'mention_notif',
                'u':instance.user.username,
                'id':instance.post.id,
                'n_id':notif.id,
                'time':time,
                'dp':instance.user.profile.profile_pic.url
            }
            async_to_sync(channel_layer.group_send)(user.username,_dict)


@app.task()
def tell_them_i_have_changed_my_dp(id):
    instance = User.objects.get(id=id)
    user_id = instance.id
    friends_qs = instance.profile.friends.all()
    channel_layer = get_channel_layer()
    for friend in friends_qs:
        notif = Notification(notif_to=friend,ref_id=str(user_id),type="dp_notif")
        notif.save()
        if friend.profile.online:
            _dict = {
                'type':'dp_update',
                'id':user_id,
                'n_id':notif.id,
            }
            async_to_sync(channel_layer.group_send)(friend.username, _dict)
