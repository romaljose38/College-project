from django.urls import path
from . import views
from . import api_views


urlpatterns = [
    path('register', views.register , name="register"),
    path('login', api_views.login, name="login_api"),
    path('post_upload', api_views.post_upload_handler, name="post_upload"),
    path('users',api_views.get_user_list, name="user list"),
    path('friends', api_views.get_friends_list, name="friends list"),
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
    path('add_story_comment', api_views.user_story_commented, name="story_comments"),
    path('story_delete', api_views.story_delete_handler, name="story_delete"),
    path('upload_chat_image',api_views.upload_chat_media, name="chat_image_upload"),
    path('upload_chat_audio',api_views.upload_chat_audio, name="chat_audio_upload"),
    path('upload_chat_audio_reply',api_views.upload_chat_audio_reply, name="chat_audio_reply_upload"),
    path('upload_chat_image_reply',api_views.upload_chat_image_reply, name="chat_image_reply_upload"),
    path('people_you_may_know', api_views.people_you_may_know, name="suggestions"),
    path('delete_post', api_views.delete_post, name="delete_post"),
    path('dob_upload', api_views.dob_upload,  name="dob_upload"),
    path('user_details', api_views.get_user_details, name="get_user_details"),
    path('update_details', api_views.update_user_details, name="update_user_details"),
    path('check_password', api_views.password_check, name="check_password"),
    path('change_password', api_views.password_change, name="change_password"),
    path('delete_account', api_views.delete_account, name="account_delete"),
    path('last_seen', api_views.add_to_last_seen, name='add_last_seen_personal'),
    path('last_seen_general', api_views.switch_off_last_seen, name='switch_off_last_seen_all'),


]