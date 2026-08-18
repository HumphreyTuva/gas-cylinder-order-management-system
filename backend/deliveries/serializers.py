from rest_framework import serializers

from .models import Delivery


class DeliverySerializer(serializers.ModelSerializer):
    order_number = serializers.CharField(source="order.order_number", read_only=True)
    customer_username = serializers.CharField(source="order.customer.username", read_only=True)
    assigned_to_username = serializers.CharField(source="assigned_to.username", read_only=True, default=None)

    class Meta:
        model = Delivery
        fields = [
            "id", "order", "order_number", "customer_username", "assigned_to", "assigned_to_username",
            "status", "delivery_address", "scheduled_time", "delivered_at", "failure_reason",
            "notes", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "order", "order_number", "customer_username", "created_at", "updated_at"]
