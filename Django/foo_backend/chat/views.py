from django.shortcuts import render
from django.contrib.auth.decorators import login_required
# Create your views here.

def test_only(request):
    return render(request,'test_room.html')

@login_required(login_url="/login")
def get_room(request):
    return render(request, 'chat_room.html')