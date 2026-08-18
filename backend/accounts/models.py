import uuid
from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    Custom user model supporting three roles as described in the proposal:
    - customer: places orders, pays, tracks deliveries
    - staff: processes orders, confirms payments, manages deliveries
    - management: administrative dashboard, full oversight, manages staff/users
    """

    class Role(models.TextChoices):
        CUSTOMER = "customer", "Customer"
        STAFF = "staff", "Staff"
        MANAGEMENT = "management", "Management"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.CUSTOMER)
    phone_number = models.CharField(max_length=20, unique=True)
    email = models.EmailField(unique=True, blank=True, null=True)
    default_delivery_address = models.CharField(max_length=255, blank=True, null=True)
    fcm_token = models.CharField(max_length=255, blank=True, null=True)
    is_active_staff = models.BooleanField(
        default=True, help_text="Allows management to deactivate staff accounts without deleting them."
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = "username"
    REQUIRED_FIELDS = ["phone_number"]

    def __str__(self):
        return f"{self.username} ({self.role})"

    @property
    def is_customer(self):
        return self.role == self.Role.CUSTOMER

    @property
    def is_staff_member(self):
        return self.role == self.Role.STAFF

    @property
    def is_management(self):
        return self.role == self.Role.MANAGEMENT
