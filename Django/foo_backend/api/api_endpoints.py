from django.urls import path
from . import views
from . import api_views


urlpatterns = [
    path('register', views.register , name="register"),
    path('login', api_views.login, name="login_api"),
    path('upload', api_views.video_upload_handler, name="video_upload"),
    path('users',api_views.get_user_list, name="user list"),
    path('<str:username>/posts',api_views.get_posts, name="post list"),
    path('<int:id>/profile',api_views.get_profile_and_posts, name="profile details"),
    path('<int:id>/post_detail',api_views.get_comments, name="post details"),
    path('<str:username>/add_comment',api_views.add_comment, name="add comment"),
    path('add_like',api_views.like_post, name="like post"),
    path('remove_like',api_views.dislike_post, name="dislike post"),
    path('add_friend',api_views.send_friend_request, name="add friend"),
    path('handle_request',api_views.handle_friend_request, name="handle_request"),
    path('get_stories', api_views.get_stories, name="get_stories"),
    path('get_status', api_views.get_status, name="get_status"),
    path('story_upload', api_views.story_upload_handler, name="story_upload"),
    path('ping', api_views.ping, name="ping"),
    path('<str:username>/get_previous_posts', api_views.get_previous_posts, name="previous_posts"),
    path('add_view', api_views.user_story_viewed, name="story_views"),

]