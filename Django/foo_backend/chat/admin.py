from django.contrib import admin
from .models import (
	Profile,
	Thread,
	ChatMessage,
    User,
    Post,
    Comment,
    FriendRequest,
    Notification,
    Story,
    Comment,
    StoryNotification,
)
# from django.contrib.auth.models import User
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import Group
# Register your models here.

from django import forms
from django.contrib.auth.forms import ReadOnlyPasswordHashField
from django.core.exceptions import ValidationError


class UserCreationForm(forms.ModelForm):
    """A form for creating new users. Includes all the required
    fields, plus a repeated password."""
    password1 = forms.CharField(label='Password', widget=forms.PasswordInput)
    password2 = forms.CharField(label='Password confirmation', widget=forms.PasswordInput)

    class Meta:
        model = User
        fields = ('email', 'token','username')

    def clean_password2(self):
        # Check that the two password entries match
        password1 = self.cleaned_data.get("password1")
        password2 = self.cleaned_data.get("password2")
        if password1 and password2 and password1 != password2:
            raise ValidationError("Passwords don't match")
        return password2

    def save(self, commit=True):
        # Save the provided password in hashed format
        user = super().save(commit=False)
        user.set_password(self.cleaned_data["password1"])
        if commit:
            user.save()
        return user


class UserChangeForm(forms.ModelForm):
    """A form for updating users. Includes all the fields on
    the user, but replaces the password field with admin's
    disabled password hash display field.
    """
    password = ReadOnlyPasswordHashField()

    class Meta:
        model = User
        fields = ('email', 'password', 'token','username', 'is_active')

# Each user has a unique profile. So it would be better if it showed along with User model in admin panel
class ProfileInline(admin.StackedInline):
	model = Profile

# Custom admin for custom user
class UserAdmin(BaseUserAdmin):
    form = UserChangeForm
    add_form = UserCreationForm
    list_display = ['email', 'uprn','admin']
    list_filter = ['admin']
    fieldsets = (
        (None, {'fields': ('email','uprn','username', 'password')}),
        ('Personal info', {'fields': ('token',)}),
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
admin.site.register(FriendRequest)
admin.site.register(Notification)
admin.site.register(Story)
admin.site.register(Comment)
admin.site.register(StoryNotification)


