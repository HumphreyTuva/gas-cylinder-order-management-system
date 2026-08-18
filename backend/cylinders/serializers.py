from rest_framework import serializers

from .models import CustomerCylinder, CylinderType


class CylinderTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = CylinderType
        fields = [
            "id", "name", "size_kg", "purchase_price", "refill_price",
            "description", "is_active", "stock_quantity", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class CustomerCylinderSerializer(serializers.ModelSerializer):
    cylinder_type_detail = CylinderTypeSerializer(source="cylinder_type", read_only=True)

    class Meta:
        model = CustomerCylinder
        fields = ["id", "customer", "cylinder_type", "cylinder_type_detail", "serial_number", "registered_at"]
        read_only_fields = ["id", "customer", "registered_at"]
