from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from channels.layers import get_channel_layer
# Create your views here.

def test_only(request):
    return render(request,'test_room.html')




@login_required(login_url="/login")
def get_room(request):
    return render(request, 'chat_room.html',context={"user":request.user.username})




