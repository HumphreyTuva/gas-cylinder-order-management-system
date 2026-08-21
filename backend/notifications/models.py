import uuid
from django.conf import settings
from django.db import models


class Notification(models.Model):
    class Type(models.TextChoices):
        ORDER_CONFIRMATION = "order_confirmation", "Order Confirmation"
        PAYMENT_CONFIRMATION = "payment_confirmation", "Payment Confirmation"
        ORDER_PROCESSING = "order_processing", "Order Processing"
        ORDER_DISPATCHED = "order_dispatched", "Order Dispatched"
        OUT_FOR_DELIVERY = "out_for_delivery", "Out for Delivery"
        DELIVERY_COMPLETED = "delivery_completed", "Delivery Completed"
        ORDER_CANCELLED = "order_cancelled", "Order Cancelled/Rejected"
        GENERAL = "general", "General"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    notification_type = models.CharField(max_length=30, choices=Type.choices, default=Type.GENERAL)
    title = models.CharField(max_length=150)
    message = models.TextField()
    related_order = models.ForeignKey(
        "orders.Order", on_delete=models.CASCADE, null=True, blank=True, related_name="notifications"
    )
    is_read = models.BooleanField(default=False)
    sent_via_push = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} -> {self.user.username}"


class DeviceToken(models.Model):
    """
    A single physical device's FCM push token, linked to whichever user is
    currently logged in on it. A user can have several of these (logged in
    on their phone AND an emulator/tablet simultaneously) -- notifications
    are sent to all of a user's registered devices.

    The token itself is the unique key: if the same device later logs in as
    a different user, re-registering the token reassigns it to that new
    user rather than leaving it stuck pointing at whoever used it before.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="device_tokens")
    token = models.CharField(max_length=255, unique=True)
    platform = models.CharField(max_length=20, default="android")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} ({self.platform})"
