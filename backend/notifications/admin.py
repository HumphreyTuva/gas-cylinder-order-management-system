from django.contrib import admin

from .models import DeviceToken, Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("title", "user", "notification_type", "is_read", "sent_via_push", "created_at")
    list_filter = ("notification_type", "is_read", "sent_via_push")


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = ("user", "platform", "token", "created_at", "updated_at")
    search_fields = ("user__username", "token")
