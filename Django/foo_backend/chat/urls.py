from django.urls import path
from . import views

urlpatterns = [
    path('test/', views.test_only, name="development"),
    path('room/', views.get_room, name="room")
]