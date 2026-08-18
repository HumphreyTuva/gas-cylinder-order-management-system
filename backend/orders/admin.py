from django.contrib import admin

from .models import Order, OrderStatusHistory


class OrderStatusHistoryInline(admin.TabularInline):
    model = OrderStatusHistory
    extra = 0
    readonly_fields = ("status", "changed_by", "note", "changed_at")


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ("order_number", "customer", "order_type", "cylinder_type", "status", "total_amount", "created_at")
    list_filter = ("status", "order_type")
    search_fields = ("order_number", "customer__username", "delivery_phone_number")
    inlines = [OrderStatusHistoryInline]


@admin.register(OrderStatusHistory)
class OrderStatusHistoryAdmin(admin.ModelAdmin):
    list_display = ("order", "status", "changed_by", "changed_at")
