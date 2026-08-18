from rest_framework import serializers

from cylinders.serializers import CylinderTypeSerializer
from .models import Order, OrderStatusHistory


class OrderStatusHistorySerializer(serializers.ModelSerializer):
    changed_by_username = serializers.CharField(source="changed_by.username", read_only=True, default=None)

    class Meta:
        model = OrderStatusHistory
        fields = ["id", "status", "changed_by", "changed_by_username", "note", "changed_at"]
        read_only_fields = fields


class OrderSerializer(serializers.ModelSerializer):
    cylinder_type_detail = CylinderTypeSerializer(source="cylinder_type", read_only=True)
    customer_username = serializers.CharField(source="customer.username", read_only=True)
    status_history = OrderStatusHistorySerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = [
            "id", "order_number", "customer", "customer_username", "order_type",
            "cylinder_type", "cylinder_type_detail", "quantity", "status",
            "delivery_address", "delivery_phone_number", "delivery_notes",
            "total_amount", "handled_by", "status_history", "created_at", "updated_at",
        ]
        read_only_fields = [
            "id", "order_number", "customer", "status", "total_amount",
            "handled_by", "status_history", "created_at", "updated_at",
        ]

    def validate(self, attrs):
        order_type = attrs.get("order_type")
        cylinder_type = attrs.get("cylinder_type")
        if order_type == Order.OrderType.PURCHASE and cylinder_type and cylinder_type.stock_quantity < attrs.get("quantity", 1):
            raise serializers.ValidationError({"quantity": "Insufficient stock for this cylinder size."})
        return attrs

    def create(self, validated_data):
        request = self.context["request"]
        validated_data["customer"] = request.user
        return super().create(validated_data)


class OrderStatusUpdateSerializer(serializers.Serializer):
    """Used by staff/management to transition an order's status."""

    status = serializers.ChoiceField(choices=Order.Status.choices)
    note = serializers.CharField(required=False, allow_blank=True)

    # Simple allowed-transition map to prevent nonsensical status jumps.
    ALLOWED_TRANSITIONS = {
        Order.Status.PENDING: {Order.Status.CONFIRMED, Order.Status.REJECTED, Order.Status.CANCELLED},
        Order.Status.CONFIRMED: {Order.Status.PROCESSING, Order.Status.CANCELLED},
        Order.Status.PROCESSING: {Order.Status.OUT_FOR_DELIVERY, Order.Status.CANCELLED},
        Order.Status.OUT_FOR_DELIVERY: {Order.Status.DELIVERED, Order.Status.FAILED_DELIVERY},
        Order.Status.FAILED_DELIVERY: {Order.Status.OUT_FOR_DELIVERY, Order.Status.CANCELLED},
        Order.Status.DELIVERED: set(),
        Order.Status.CANCELLED: set(),
        Order.Status.REJECTED: set(),
    }

    def validate(self, attrs):
        order = self.context["order"]
        new_status = attrs["status"]
        allowed = self.ALLOWED_TRANSITIONS.get(order.status, set())
        if new_status not in allowed and new_status != order.status:
            raise serializers.ValidationError(
                f"Cannot transition order from '{order.status}' to '{new_status}'."
            )
        return attrs
