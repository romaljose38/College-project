from django.db.models.signals import post_save
from .models import Profile
from django.conf import settings
from django.dispatch import receiver
from django.contrib.auth import get_user_model


User = get_user_model()

# Signal to create a profile when a user object is created
@receiver(post_save,sender=User)
def create_profile(sender, instance, created, **kwargs):
    if created:
        profile = Profile.objects.create(user=instance)
        profile.save()

