from django.db.models.signals import post_save,m2m_changed
from .models import Profile,ChatMessage
from django.conf import settings
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from channels.db import database_sync_to_async


User = get_user_model()

# Signal to create a profile when a user object is created
@receiver(post_save,sender=User)
def create_profile(sender, instance, created, **kwargs):
    if created:
        profile = Profile.objects.create(user=instance)
        profile.save()



# @database_sync_to_async
# def get_user_status(user):
#     return user.profile.online

# @database_sync_to_async
# def get_user_from_id(id):
#     return 


# async def send_notif(user,id,from_username):
#     channel_layer = get_channel_layer()
    
#     status = await get_user_status(user)
#     if status:
#         message = { 
#                     'to':user.username,
#                     'message':{'received':id },
#                     'from':from_username,
#                 }

#         await channel_layer.group_send(
#             'common_room',
#             {"type": "chat_message", "message": message},
#         )
#         print("in here")


# def inform_user(sender, instance, pk_set, **kwargs):
#     print(instance.user, pk_set)
#     id=list(pk_set)[0]
#     user = User.objects.get(id=id)
#     if user!=instance.user:
#         async_to_sync(send_notif)(instance.user,id,user.username)


# m2m_changed.connect(inform_user,sender=ChatMessage.recipients.through)