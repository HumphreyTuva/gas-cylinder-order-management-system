from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    InitiateCardPaymentView,
    InitiateMpesaPaymentView,
    MpesaCallbackView,
    PaymentViewSet,
)

router = DefaultRouter()
router.register("", PaymentViewSet, basename="payment")

urlpatterns = [
    path("mpesa/initiate/", InitiateMpesaPaymentView.as_view(), name="mpesa-initiate"),
    path("mpesa/callback/", MpesaCallbackView.as_view(), name="mpesa-callback"),
    path("card/initiate/", InitiateCardPaymentView.as_view(), name="card-initiate"),
] + router.urls
