"""
ASGI config for foo_backend project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/3.2/howto/deployment/asgi/
"""

import os

from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter, ChannelNameRouter
from django.core.asgi import get_asgi_application
import chat.routing
import chat.consumers

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "foo_backend.settings")

application = ProtocolTypeRouter({
  "http": get_asgi_application(),
 
  "websocket": AuthMiddlewareStack(
        URLRouter(
            chat.routing.websocket_urlpatterns
        )
    ),

   

})