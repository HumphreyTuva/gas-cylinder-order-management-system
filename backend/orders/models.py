import uuid
from django.conf import settings
from django.db import models

from cylinders.models import CylinderType


class Order(models.Model):
    class OrderType(models.TextChoices):
        PURCHASE = "purchase", "New Cylinder Purchase"
        REFILL = "refill", "Cylinder Refill"

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        CONFIRMED = "confirmed", "Confirmed"
        PROCESSING = "processing", "Processing"
        OUT_FOR_DELIVERY = "out_for_delivery", "Out for Delivery"
        DELIVERED = "delivered", "Delivered"
        CANCELLED = "cancelled", "Cancelled"
        REJECTED = "rejected", "Rejected"
        FAILED_DELIVERY = "failed_delivery", "Failed Delivery"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_number = models.CharField(max_length=20, unique=True, editable=False)
    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="orders"
    )
    order_type = models.CharField(max_length=10, choices=OrderType.choices)
    cylinder_type = models.ForeignKey(CylinderType, on_delete=models.PROTECT, related_name="orders")
    quantity = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)

    delivery_address = models.CharField(max_length=255)
    delivery_phone_number = models.CharField(max_length=20)
    delivery_notes = models.TextField(blank=True, null=True)

    total_amount = models.DecimalField(max_digits=10, decimal_places=2)

    handled_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="handled_orders", help_text="Staff member currently processing this order.",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Order {self.order_number} ({self.get_status_display()})"

    def save(self, *args, **kwargs):
        if not self.order_number:
            self.order_number = f"ORD-{uuid.uuid4().hex[:8].upper()}"
        if not self.total_amount:
            unit_price = (
                self.cylinder_type.purchase_price
                if self.order_type == self.OrderType.PURCHASE
                else self.cylinder_type.refill_price
            )
            self.total_amount = unit_price * self.quantity
        super().save(*args, **kwargs)


class OrderStatusHistory(models.Model):
    """Audit trail: every status transition, for accountability and activity monitoring."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="status_history")
    status = models.CharField(max_length=20, choices=Order.Status.choices)
    changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="order_status_changes"
    )
    note = models.CharField(max_length=255, blank=True, null=True)
    changed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["changed_at"]
        verbose_name_plural = "Order status histories"

    def __str__(self):
        return f"{self.order.order_number} -> {self.status}"
