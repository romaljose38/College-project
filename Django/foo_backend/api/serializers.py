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
        fields = ['f_name','l_name','email','password','uprn','username','token']
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
        user.f_name = validated_data['f_name']
        user.l_name = validated_data['l_name']
        user.username = validated_data['username']
        user.token = validated_data['token']
        user.save()
        return user


class UserCustomSerializer(serializers.ModelSerializer):

    class Meta:
        model = User
        fields = ['username','f_name','l_name','id']

class PostSerializer(serializers.ModelSerializer):
    user = UserCustomSerializer()

    class Meta:

        model = Post
        fields = ["file","user",'id']


    def to_representation(self, instance):
        representation = super().to_representation(instance)
        user = self.context['user']
        if user in instance.likes.all():
            representation['hasLiked'] = True
        else:
            representation['hasLiked'] = False
        representation['likeCount'] = instance.likes.count()
        return representation


class PostRelatedField(serializers.RelatedField):

    def to_representation(self,instance):
      
        return {'id':instance.id,'url':instance.file.url,'likes':instance.likes.count()}

    def get_queryset(self):
        return Post.objects.all()



class UserProfileSerializer(serializers.ModelSerializer):

    posts = PostRelatedField(many=True)

    class Meta:
        model = User
        fields = ["f_name","l_name","username","id","email","posts"]
        # depth = 1


    def to_representation(self,instance):
        representation = super().to_representation(instance)
        request = self.context['request']
        cur_user = self.context['cur_user']
        if instance==cur_user:
            representation['isMe'] = True
        else:
            representation['isMe'] = False
        print(request.count())
        if (request.count() == 1):
            if request.first().status == "accepted":
                representation['requestStatus'] = "accepted"
            elif request.first().status == "pending":
                representation['requestStatus'] = "pending"
            elif request.first().status == "rejected":
                representation['requestStatus'] = "rejected"
        else:
            representation['requestStatus'] = "open"


        return representation


class CommentRelatedField(serializers.RelatedField):

    def to_representation(self,instance):
        return {'comment':instance.comment, 'id':instance.id, 'user':instance.user.username}

    def get_queryset(self):
        return Comment.objects.all()

class PostDetailSerializer(serializers.ModelSerializer):

    comment_set = CommentRelatedField(many=True)

    class Meta:
        model = Post
        fields = ['file','caption','post_type','comment_set']




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
