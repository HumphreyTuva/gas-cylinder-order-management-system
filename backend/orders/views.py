from django.db import transaction
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.permissions import IsOwnerOrStaffOrManagement, IsStaffOrManagement
from notifications.services import notify_order_status_change
from .models import Order, OrderStatusHistory
from .serializers import OrderSerializer, OrderStatusUpdateSerializer


class OrderViewSet(viewsets.ModelViewSet):
    """
    Customer: create + view own orders (list/retrieve), cancel while pending.
    Staff/Management: view all orders, update status, assign handler.

    Endpoints:
      GET/POST   /api/orders/
      GET        /api/orders/{id}/
      POST       /api/orders/{id}/update_status/
      POST       /api/orders/{id}/assign_to_me/
    """

    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrStaffOrManagement]

    def get_queryset(self):
        user = self.request.user
        qs = Order.objects.select_related("customer", "cylinder_type", "handled_by").prefetch_related("status_history")
        if user.is_staff_member or user.is_management:
            status_filter = self.request.query_params.get("status")
            if status_filter:
                qs = qs.filter(status=status_filter)
            return qs
        return qs.filter(customer=user)

    def perform_create(self, serializer):
        order = serializer.save(customer=self.request.user)
        OrderStatusHistory.objects.create(order=order, status=order.status, changed_by=self.request.user, note="Order placed.")

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, IsStaffOrManagement])
    def update_status(self, request, pk=None):
        order = self.get_object()
        serializer = OrderStatusUpdateSerializer(data=request.data, context={"order": order})
        serializer.is_valid(raise_exception=True)
        new_status = serializer.validated_data["status"]
        note = serializer.validated_data.get("note", "")

        with transaction.atomic():
            order.status = new_status
            order.save(update_fields=["status", "updated_at"])
            OrderStatusHistory.objects.create(order=order, status=new_status, changed_by=request.user, note=note)

        notify_order_status_change(order)
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, IsStaffOrManagement])
    def assign_to_me(self, request, pk=None):
        order = self.get_object()
        order.handled_by = request.user
        order.save(update_fields=["handled_by", "updated_at"])
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, IsOwnerOrStaffOrManagement])
    def cancel(self, request, pk=None):
        order = self.get_object()
        if order.status != Order.Status.PENDING:
            return Response(
                {"detail": "Only pending orders can be cancelled by the customer."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        order.status = Order.Status.CANCELLED
        order.save(update_fields=["status", "updated_at"])
        OrderStatusHistory.objects.create(order=order, status=order.status, changed_by=request.user, note="Cancelled by customer.")
        notify_order_status_change(order)
        return Response(OrderSerializer(order).data)
