from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ("username", "phone_number", "email", "role", "is_active", "is_active_staff")
    list_filter = ("role", "is_active")
    fieldsets = BaseUserAdmin.fieldsets + (
        ("Gas Cylinder System", {"fields": ("role", "phone_number", "default_delivery_address", "fcm_token", "is_active_staff")}),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ("Gas Cylinder System", {"fields": ("role", "phone_number", "email")}),
    )
