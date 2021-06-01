from django.shortcuts import render
from django.contrib import auth
from django.shortcuts import redirect
from rest_framework.decorators import api_view
from .serializers import UserSerializer
from rest_framework.response import Response
from django.views.decorators.csrf import csrf_exempt

# Create your views here.


def login(request):
    if request.method == "GET":

        return render(request, 'login.html')
    elif request.method == "POST":
        email = request.POST.get('email')
        password = request.POST.get('password')

        user = auth.authenticate(email=email,password=password)
        
        if user is not None:
            auth.login(request,user)
            return redirect('/chat/room')
        else:
            return render(request,'login.html')

@csrf_exempt
@api_view(['POST'])                                               # To ensure only post requests can access this view
def register(request):
    serialized = UserSerializer(data=request.data)
    if serialized.is_valid():
        user = serialized.save()
        serialized.validated_data['id'] = user.id
        return Response(serialized.validated_data)
    else:
        return Response(status=400,data=serialized.errors)
