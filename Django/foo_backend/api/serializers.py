from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):

    class Meta:

        model = User
        fields = ['f_name','l_name','email','password','uprn','username']
        extra_kwargs = {
            'password':{'write_only':True},
            'uprn':{'required':True} 
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
        user.save()
        return user
