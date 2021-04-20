from django.urls import path
from . import views
from . import api_views


urlpatterns = [
    path('register', views.register , name="register"),
    path('login', api_views.login, name="login_api")
]