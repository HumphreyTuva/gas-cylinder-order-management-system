from django.contrib import admin

from .models import Delivery


@admin.register(Delivery)
class DeliveryAdmin(admin.ModelAdmin):
    list_display = ("order", "assigned_to", "status", "scheduled_time", "delivered_at")
    list_filter = ("status",)
