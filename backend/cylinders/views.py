from rest_framework import viewsets

from accounts.permissions import ReadOnlyOrStaffOrManagement
from .models import CustomerCylinder, CylinderType
from .serializers import CustomerCylinderSerializer, CylinderTypeSerializer


class CylinderTypeViewSet(viewsets.ModelViewSet):
    """
    Cylinder catalogue: sizes, purchase/refill prices, stock.
    Any authenticated user can browse (customers picking a cylinder to order);
    only staff/management can create/edit/delete.
    """

    queryset = CylinderType.objects.all()
    serializer_class = CylinderTypeSerializer
    permission_classes = [ReadOnlyOrStaffOrManagement]


class CustomerCylinderViewSet(viewsets.ModelViewSet):
    """
    Cylinders registered/owned by the logged-in customer (used to request refills).
    Staff/management see all; customers see only their own.
    """

    serializer_class = CustomerCylinderSerializer

    def get_permissions(self):
        from rest_framework.permissions import IsAuthenticated
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        qs = CustomerCylinder.objects.select_related("cylinder_type", "customer")
        if user.is_staff_member or user.is_management:
            return qs
        return qs.filter(customer=user)

    def perform_create(self, serializer):
        user = self.request.user
        if user.is_customer:
            serializer.save(customer=user)
        else:
            serializer.save()
