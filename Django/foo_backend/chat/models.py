from django.db import models
from django.db.models import Q
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.utils import timezone
from django.db.models.signals import post_save
# Create your models here.


# =============================
# Custom user model and manager
# =============================
class UserManager(BaseUserManager):
    def create_user(self, email, password=None):
        """
        Creates and saves a User with the given email and password.
        """
        if not email:
            raise ValueError('Users must have an email address')

        user = self.model(
            email=self.normalize_email(email),
        )

        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_staffuser(self, email, password):
        """
        Creates and saves a staff user with the given email and password.
        """
        user = self.create_user(
            email,
            password=password,
        )
        user.staff = True
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password):
        """
        Creates and saves a superuser with the given email and password.
        """
        user = self.create_user(
            email,
            password=password,
        )
        user.staff = True
        user.admin = True
        user.save(using=self._db)
        return user



class User(AbstractBaseUser):
    email = models.EmailField(
        verbose_name='email address',
        max_length=255,
        unique=True,
    )
    f_name = models.CharField(max_length=50)
    l_name = models.CharField(max_length=50)
    username = models.CharField(max_length=50,)
    uprn = models.IntegerField(null=True,blank=False,unique=True)
    token = models.CharField(max_length=240,null=True,unique=True)
    dob = models.DateField(null=True,blank=True)
    is_active = models.BooleanField(default=True)
    staff = models.BooleanField(default=False) # a admin user; non super-user
    admin = models.BooleanField(default=False)
    username_alias = models.CharField(max_length=100, unique=True, null=True, blank=True) # a superuser
    about = models.TextField(default='')
    #about =models.TextField(blank=True,null=True)
    # notice the absence of a "Password field", that is built in.

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = [] # Email & Password are required by default.


    objects = UserManager()

    def __str__(self):
        return self.email

    def has_perm(self, perm, obj=None):
        "Does the user have a specific permission?"
        # Simplest possible answer: Yes, always
        return True

    def has_module_perms(self, app_label):
        "Does the user have permissions to view the app `app_label`?"
        # Simplest possible answer: Yes, always
        return True

    @property
    def is_staff(self):
        "Is the user a member of staff?"
        return self.staff

    @property
    def is_admin(self):
        "Is the user a admin member?"
        return self.admin

def profile_pic_path(instance, filename):

    return 'user_{0}/profile/dp.jpg'.format(instance.user.id)
  

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    online = models.BooleanField(default=False)
    last_seen = models.DateTimeField(auto_now=False, auto_now_add=True)
    profile_pic = models.FileField(upload_to=profile_pic_path, null=True, blank=True)
    people_i_should_inform = models.ManyToManyField(User, related_name="cctvs", blank=True)
    people_i_peek = models.ManyToManyField(User, related_name="watching", blank=True)
    friends = models.ManyToManyField(User, related_name="friends", blank=True)
    yall_cant_see_me = models.ManyToManyField(User, related_name="hidden_last_seen", blank=True)
    general_last_seen_off = models.BooleanField(default=False)

    def __str__(self):
        return f'{self.user.email}'



class ThreadManager(models.Manager):

    def get_or_new(self,user,username):
       
        first_username = user.username
        first_lookup = Q(first__username=first_username) & Q(second__username=username)
        second_lookup = Q(first__username=username) & Q(second__username=first_username)
        qs =  self.get_queryset().filter(first_lookup | second_lookup).distinct()
        if qs.count() == 1:
            return qs.first()
        else:
            Klass = user.__class__
            other_user = Klass.objects.all().get(username=username)
            if user != other_user:
                obj = self.model(
                    first = user,
                    second=other_user
                )
                obj.save()
                return obj
        



class Thread(models.Model):
    first  = models.ForeignKey(User,related_name="first_thred", on_delete=models.CASCADE)
    second  = models.ForeignKey(User,related_name="second_thread", on_delete=models.CASCADE)

    objects = ThreadManager()

    def __str__(self):
        return f'{self.first.email}-{self.second.email}'


def media_path(instance, filename):

    return 'user_{0}/messages/{1}'.format(instance.user.id, filename)
  


class ChatMessage(models.Model):

    MSG_TYPES = (('msg','msg'),('img','img'),('aud','aud'),('reply_txt','reply_txt'),('reply_img','reply_img'),('reply_txt','reply_txt'))

    thread = models.ForeignKey(Thread, on_delete=models.CASCADE)
    user   = models.ForeignKey(User, related_name="sender", on_delete=models.CASCADE)
    message = models.TextField(null=True,blank=True)
    time_created = models.CharField(max_length=30,null=True)
    recipients = models.ManyToManyField(User, blank=True)
    msg_type = models.CharField(max_length=10,null=True,blank=True,choices=MSG_TYPES)
    file = models.FileField(upload_to=media_path,null=True)
    reply_txt = models.TextField(blank=True,null=True)
    reply_id = models.IntegerField(blank=True,null=True)

    def received(self):
        if self.recipients.all().count() == 2:
            return True
        return False

class Notification(models.Model):

    NOTIF_TYPES = (('seen','seen'),('received','received'),('s_reached','s_reached'),('delete','delete'))

    ref_id = models.CharField(null=True,max_length=20)
    chatmsg_id = models.IntegerField(null=True)
    notif_from = models.ForeignKey(User, related_name="from_user_chat", on_delete=models.CASCADE, null=True)
    notif_to = models.ForeignKey(User, related_name="to_user_chat", on_delete=models.CASCADE)
    notif_type = models.CharField(max_length=10,choices=NOTIF_TYPES)
    chat_username = models.CharField(max_length=100,null=True,blank=True)

def user_directory_path(instance, filename):
    extension = filename.split(".")[-1]
    return 'user_{0}/{1}'.format(instance.user.id, filename[:4]+'.'+extension)

def post_thumbnail_path(instance, filename):
    extension = filename.split(".")[-1]
    return 'user_{0}/thumbnails/{1}'.format(instance.user.id, filename[:4]+'.'+extension)


class Post(models.Model):
    
    user = models.ForeignKey(User, related_name="posts", on_delete=models.CASCADE)
    file = models.FileField(upload_to = user_directory_path)
    post_type = models.CharField(max_length=15)
    time_created = models.DateTimeField(auto_now_add=True)
    caption = models.CharField(max_length=100)
    thumbnail = models.FileField(upload_to = post_thumbnail_path, null=True, blank=True)

    likes = models.ManyToManyField(User,related_name="likes", blank=True)


    def have_liked(self,user):
        if user in likes:
            return True
        return False
        

class Comment(models.Model):

    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    comment = models.CharField(max_length=1000)
    time_created = models.DateTimeField(auto_now_add=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE,related_name="mentions")
    mentions = models.ManyToManyField(User, blank=True)




class FriendRequest(models.Model):

    STATES = (('pending','pending'),('accepted','accepted'),('rejected','rejected'))


    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="from_user")
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="to_user")
    status = models.CharField(max_length=10, choices=STATES)
    has_received = models.BooleanField(default=False)
    time_created = models.CharField(max_length=70, blank=True, null=True)




def user_story_directory_path(instance, filename):
    extension = filename.split(".")[-1]
    return 'user_{0}/stories/{1}'.format(instance.user.id, filename[:4]+'.'+extension)

class Story(models.Model):

    user = models.ForeignKey(User, related_name="stories", on_delete=models.CASCADE)
    file = models.FileField(upload_to=user_story_directory_path)
    caption = models.TextField(max_length=1000)
    time_created = models.DateTimeField(auto_now_add=True)
    views = models.ManyToManyField(User, related_name="story_views", blank=True)
    
class StoryComment(models.Model):

    user = models.ForeignKey(User,on_delete=models.CASCADE, null=True)
    story = models.ForeignKey(Story, related_name="story_comment", on_delete=models.CASCADE)
    comment = models.TextField(max_length=1000)
    time_created = models.DateTimeField(auto_now_add=True)

class StoryNotification(models.Model):
    STORY_NOTIF_TYPES = (('story_add','story_add'),('story_del','story_del'),('story_view','story_view'))

    story = models.ForeignKey(Story, on_delete=models.CASCADE, blank=True, null=True)
    storyId = models.IntegerField(blank=True, null=True)
    to_user = models.ForeignKey(User, on_delete=models.CASCADE)
    notif_type = models.CharField(max_length=15,choices=STORY_NOTIF_TYPES)
    time_created = models.CharField(max_length=20)
    from_user = models.ForeignKey(User, on_delete=models.CASCADE,related_name="story_viewed_user", blank=True, null=True)

class MentionNotification(models.Model):

    post_id = models.IntegerField(blank = True, null=True)
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="mention_to_user")
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="mention_from_user")  
    time_created = models.CharField(max_length=70, null=True, blank=True)