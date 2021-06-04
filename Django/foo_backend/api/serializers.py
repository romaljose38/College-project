from rest_framework import serializers
from django.contrib.auth import get_user_model
from chat.models import (
Post,
Comment,
Story
)

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):

    class Meta:

        model = User
        fields = ['email','password','uprn','username','token']
        extra_kwargs = {
            'password':{'write_only':True},
            'uprn':{'required':True},
            'token':{'required':True},
            }

    # overriding the default create method. Because password is not encrypted in default create()
    def create(self,validated_data):
        
        user = User.objects.create_user(
                                            email=validated_data['email'],
                                            password=validated_data['password']
                                        )
        user.uprn = validated_data['uprn']
        user.username = validated_data['username']
        user.username_alias = validated_data['username']
        user.token = validated_data['token']
        user.save()
        return user

    def to_representation(self, instance):
        representation = super().to_representation(instance);
        representation['id'] = instance.id
        if(instance.dob is None):
            representation['dobVerified'] = False
        else:
            representation['dobVerified'] = True
            representation['dp'] = instance.profile.profile_pic.url if instance.profile.profile_pic else ''
        return representation


class UserCustomSerializer(serializers.ModelSerializer):

    class Meta:
        model = User
        fields = ['f_name','l_name','id']

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        representation['username'] = instance.username_alias
        representation['dp'] = instance.profile.profile_pic.url if instance.profile.profile_pic else ''
        return representation

class PostSerializer(serializers.ModelSerializer):
    user = UserCustomSerializer()

    class Meta:

        model = Post
        fields = ["file","user",'id',"post_type",'caption']


    def to_representation(self, instance):
        representation = super().to_representation(instance)
        user = self.context['user']
        representation['thumbnail'] = instance.thumbnail.url if instance.thumbnail else ''
        representation['comment_count']=instance.comment_set.all().count()
        if user in instance.likes.all():
            representation['hasLiked'] = True
        else:
            representation['hasLiked'] = False
        representation['likeCount'] = instance.likes.count()
        return representation


class PostRelatedField(serializers.RelatedField):

    def to_representation(self,instance):
      
        return {'id':instance.id,
                'url':instance.file.url,
                'likes':instance.likes.count(),
                'type':instance.post_type,
                'comments':instance.comment_set.all().count(),
                'thumbnail':instance.thumbnail.url if instance.thumbnail else ""}

    def get_queryset(self):
        return Post.objects.all()



class UserProfileSerializer(serializers.ModelSerializer):

    posts = PostRelatedField(many=True)

    class Meta:
        model = User
        fields = ["f_name","l_name","id","email","posts","about"]
        # depth = 1


    def to_representation(self,instance):
        representation = super().to_representation(instance)
        representation['username']=instance.username_alias
        request = self.context['request']
        cur_user = self.context['cur_user']
        if(instance.profile.profile_pic):
            representation['dp']=instance.profile.profile_pic.url
        
        else:
            representation['dp']=''
        if instance==cur_user:
            representation['isMe'] = True
        else:
            representation['isMe'] = False
        print(request.count())
        representation['post_count'] = instance.posts.count()
        representation['friends_count'] = instance.profile.friends.count()
        if (request.count() == 1):
            if request.first().status == "accepted":
                representation['requestStatus'] = "accepted"
            elif request.first().status == "pending":
                representation['requestStatus'] = "pending"
            elif request.first().status == "rejected":
                representation['requestStatus'] = "rejected"
        elif request.count()==0:
            if cur_user in instance.profile.friends.all():
                representation['requestStatus'] = "accepted"
            else:
                representation['requestStatus'] = "open"


        return representation


class CommentRelatedField(serializers.RelatedField):

    def to_representation(self,instance):
        return {'comment':instance.comment, 'dp':instance.user.profile.profile_pic.url, 'user':instance.user.username}

    def get_queryset(self):
        return Comment.objects.all()

class PostDetailSerializer(serializers.ModelSerializer):

    comment_set = CommentRelatedField(many=True)

    class Meta:
        model = Post
        fields = ['file','caption','post_type','comment_set','id']

    def to_representation(self,instance):
        representation = super().to_representation(instance)
        representation ['thumbnail'] = instance.thumbnail.url if instance.thumbnail else ''
        user = self.context['user']
        representation['dp'] =  instance.user.profile.profile_pic.url if instance.user.profile.profile_pic else ''
        representation['username'] = instance.user.username_alias
        representation['user_id'] = instance.user.id
        representation['comment_count']=instance.comment_set.all().count()
        if user in instance.likes.all():
            representation['hasLiked'] = True
        else:
            representation['hasLiked'] = False
        representation['likeCount'] = instance.likes.count()
        return representation



class StoryRelatedField(serializers.RelatedField):

    def to_representation(self, instance):
        return {"file":instance.file.url, "views":instance.views.count(),'time':instance.time_created.strftime("%Y-%m-%d %H:%M:%S")}

    def get_queryset(self):
        return Story.objects.all()


class UserStorySerializer(serializers.ModelSerializer):

    stories = StoryRelatedField(many=True)

    class Meta:
        model = User
        fields = ['username','id','stories']

    def to_representation(self,instance):
        if instance.stories.all().count()>0:
            representation = super().to_representation(instance)
            
            representation['dp'] = instance.profile.profile_pic.url if instance.profile.profile_pic else ''
            return representation
        else:
            return
