from django.urls import path
from . import views
from . import api_views


urlpatterns = [
    path('register', views.register , name="register"),
    path('login', api_views.login, name="login_api"),
    path('audio_upload', api_views.audio_upload_handler, name="video_upload"),
    path('users',api_views.get_user_list, name="user list"),
]