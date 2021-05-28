from django.urls import re_path,path

from . import consumers,views

websocket_urlpatterns = [
    path('ws/test_room/', consumers.DevelopmentChatConsumer.as_asgi()),
    path('ws/chat_room/<str:username>/', consumers.ChatConsumer.as_asgi()),
  


]

