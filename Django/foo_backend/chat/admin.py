from django.contrib import admin
from .models import (
	Profile,
	Thread,
	ChatMessage,
    User,
    Post,
    Comment
)
# from django.contrib.auth.models import User
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import Group
# Register your models here.

# Each user has a unique profile. So it would be better if it showed along with User model in admin panel
class ProfileInline(admin.StackedInline):
	model = Profile

# Custom admin for custom user
class UserAdmin(BaseUserAdmin):

    list_display = ['email', 'uprn','admin']
    list_filter = ['admin']
    fieldsets = (
        (None, {'fields': ('email','uprn','username', 'password')}),
        ('Personal info', {'fields': ()}),
        ('Permissions', {'fields': ('admin',)}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email','uprn','username', 'password1', 'password2')}
        ),
    )
    search_fields = ['email','uprn']
    ordering = ['email']
    filter_horizontal = ()

    inlines = [ProfileInline]

admin.site.register(User, UserAdmin)
admin.site.unregister(Group)


# To display chat messages inline in Thread model in admin

class ChatMessageInline(admin.StackedInline):
    model = ChatMessage

class ThreadAdmin(admin.ModelAdmin):
    inlines = [ChatMessageInline]


admin.site.register(Thread,ThreadAdmin)

class CommentInline(admin.StackedInline):
    model = Comment

class PostInline(admin.ModelAdmin):
    inlines = [CommentInline]

admin.site.register(Post,PostInline)
