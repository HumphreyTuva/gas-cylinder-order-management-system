import uuid
from django.conf import settings
from django.db import models


class CylinderType(models.Model):
    """Catalogue entry: e.g. '6kg', '13kg', '22.5kg' gas cylinder, with price."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)  # e.g. "13kg Gas Cylinder"
    size_kg = models.DecimalField(max_digits=6, decimal_places=2)
    purchase_price = models.DecimalField(max_digits=10, decimal_places=2)
    refill_price = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    stock_quantity = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["size_kg"]

    def __str__(self):
        return self.name


class CustomerCylinder(models.Model):
    """A physical cylinder owned/registered by a customer, used for refill requests."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="owned_cylinders"
    )
    cylinder_type = models.ForeignKey(CylinderType, on_delete=models.PROTECT, related_name="customer_units")
    serial_number = models.CharField(max_length=100, blank=True, null=True)
    registered_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.cylinder_type.name} owned by {self.customer.username}"
