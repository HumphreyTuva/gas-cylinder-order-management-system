from django.contrib.auth import get_user_model
from rest_framework import generics, permissions, status, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .permissions import IsManagement, IsStaffOrManagement
from .serializers import (
    CustomerRegistrationSerializer,
    CustomTokenObtainPairSerializer,
    FCMTokenSerializer,
    StaffCreationSerializer,
    UserSerializer,
)

User = get_user_model()


class CustomerRegisterView(generics.CreateAPIView):
    """Public endpoint: POST /api/accounts/register/ -- self-registration for customers."""

    queryset = User.objects.all()
    serializer_class = CustomerRegistrationSerializer
    permission_classes = [permissions.AllowAny]


class LoginView(TokenObtainPairView):
    """POST /api/accounts/login/ -- returns access/refresh JWT + user profile + role."""

    serializer_class = CustomTokenObtainPairSerializer


class MeView(generics.RetrieveUpdateAPIView):
    """GET/PATCH /api/accounts/me/ -- current authenticated user's profile."""

    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class RegisterFCMTokenView(APIView):
    """POST /api/accounts/fcm-token/ -- register this device's push token."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = FCMTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token = serializer.validated_data["fcm_token"]

        from notifications.models import DeviceToken

        # The token is the unique key: if this device was previously
        # registered to a different account (e.g. someone logged out and a
        # different user logged in on the same phone), this correctly moves
        # it to the current user instead of leaving it stuck on the old one.
        DeviceToken.objects.update_or_create(token=token, defaults={"user": request.user})
        return Response({"detail": "FCM token registered."}, status=status.HTTP_200_OK)


class StaffManagementViewSet(viewsets.ModelViewSet):
    """
    Management-only CRUD for staff/management accounts.
    /api/accounts/staff/  (list, create, retrieve, update, deactivate)
    """

    serializer_class = StaffCreationSerializer
    permission_classes = [IsManagement]
    queryset = User.objects.filter(role__in=[User.Role.STAFF, User.Role.MANAGEMENT])

    def perform_destroy(self, instance):
        # Soft-delete: deactivate rather than remove, to preserve audit/history trail.
        instance.is_active = False
        instance.is_active_staff = False
        instance.save(update_fields=["is_active", "is_active_staff"])


class CustomerListView(generics.ListAPIView):
    """Staff/management: browse customer records. /api/accounts/customers/"""

    serializer_class = UserSerializer
    permission_classes = [IsStaffOrManagement]
    queryset = User.objects.filter(role=User.Role.CUSTOMER)
