from django.utils import timezone
from rest_framework import permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from accounts.permissions import IsStaffOrManagement
from notifications.services import notify_delivery_status_change
from .models import Delivery
from .serializers import DeliverySerializer


class DeliveryViewSet(viewsets.ModelViewSet):
    """
    Staff/management manage deliveries (assign personnel, update status).
    Customers can view (read-only) the delivery for their own orders.
    """

    serializer_class = DeliverySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Delivery.objects.select_related("order", "order__customer", "assigned_to")
        if user.is_staff_member or user.is_management:
            return qs
        return qs.filter(order__customer=user)

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy", "assign", "mark_delivered", "mark_failed"]:
            return [permissions.IsAuthenticated(), IsStaffOrManagement()]
        return [permissions.IsAuthenticated()]

    @action(detail=True, methods=["post"])
    def assign(self, request, pk=None):
        delivery = self.get_object()
        staff_id = request.data.get("assigned_to")
        delivery.assigned_to_id = staff_id
        delivery.status = Delivery.Status.ASSIGNED
        delivery.save(update_fields=["assigned_to", "status", "updated_at"])
        notify_delivery_status_change(delivery)
        return Response(DeliverySerializer(delivery).data)

    @action(detail=True, methods=["post"])
    def mark_delivered(self, request, pk=None):
        delivery = self.get_object()
        delivery.status = Delivery.Status.DELIVERED
        delivery.delivered_at = timezone.now()
        delivery.save(update_fields=["status", "delivered_at", "updated_at"])
        notify_delivery_status_change(delivery)
        return Response(DeliverySerializer(delivery).data)

    @action(detail=True, methods=["post"])
    def mark_failed(self, request, pk=None):
        delivery = self.get_object()
        delivery.status = Delivery.Status.FAILED
        delivery.failure_reason = request.data.get("reason", "")
        delivery.save(update_fields=["status", "failure_reason", "updated_at"])
        notify_delivery_status_change(delivery)
        return Response(DeliverySerializer(delivery).data)
