from rest_framework import serializers
from django.contrib.auth import get_user_model
from chat.models import Post
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
            representation['liked'] = True
        else:
            representation['liked'] = False
        return representation