from django.contrib import admin

from .models import CustomerCylinder, CylinderType


@admin.register(CylinderType)
class CylinderTypeAdmin(admin.ModelAdmin):
    list_display = ("name", "size_kg", "purchase_price", "refill_price", "stock_quantity", "is_active")
    list_filter = ("is_active",)


@admin.register(CustomerCylinder)
class CustomerCylinderAdmin(admin.ModelAdmin):
    list_display = ("customer", "cylinder_type", "serial_number", "registered_at")
    search_fields = ("customer__username", "serial_number")
