from django.urls import path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    CustomerListView,
    CustomerRegisterView,
    LoginView,
    MeView,
    RegisterFCMTokenView,
    StaffManagementViewSet,
)

router = DefaultRouter()
router.register("staff", StaffManagementViewSet, basename="staff")

urlpatterns = [
    path("register/", CustomerRegisterView.as_view(), name="customer-register"),
    path("login/", LoginView.as_view(), name="login"),
    path("login/refresh/", TokenRefreshView.as_view(), name="login-refresh"),
    path("me/", MeView.as_view(), name="me"),
    path("fcm-token/", RegisterFCMTokenView.as_view(), name="fcm-token"),
    path("customers/", CustomerListView.as_view(), name="customer-list"),
] + router.urls
