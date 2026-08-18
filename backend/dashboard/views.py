from django.contrib.auth import get_user_model
from django.db.models import Count, Sum
from django.utils import timezone
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsStaffOrManagement
from deliveries.models import Delivery
from orders.models import Order, OrderStatusHistory
from payments.models import Payment

User = get_user_model()


class DashboardSummaryView(APIView):
    """
    GET /api/dashboard/summary/
    One-call overview for the Management Dashboard (proposal section 4.10):
    orders, customers, cylinder/payment/delivery stats, staff activity, recent transactions.
    """

    permission_classes = [IsStaffOrManagement]

    def get(self, request):
        today = timezone.now().date()

        orders_by_status = dict(
            Order.objects.values_list("status").annotate(count=Count("id")).values_list("status", "count")
        )
        payments_by_status = dict(
            Payment.objects.values_list("status").annotate(count=Count("id")).values_list("status", "count")
        )
        deliveries_by_status = dict(
            Delivery.objects.values_list("status").annotate(count=Count("id")).values_list("status", "count")
        )

        revenue_total = Payment.objects.filter(status=Payment.Status.SUCCESSFUL).aggregate(total=Sum("amount"))["total"] or 0
        revenue_today = Payment.objects.filter(
            status=Payment.Status.SUCCESSFUL, created_at__date=today
        ).aggregate(total=Sum("amount"))["total"] or 0

        recent_orders = Order.objects.select_related("customer", "cylinder_type").order_by("-created_at")[:10]
        recent_transactions = Payment.objects.select_related("order", "customer").order_by("-created_at")[:10]

        return Response({
            "totals": {
                "customers": User.objects.filter(role=User.Role.CUSTOMER).count(),
                "staff": User.objects.filter(role=User.Role.STAFF).count(),
                "orders": Order.objects.count(),
                "orders_today": Order.objects.filter(created_at__date=today).count(),
                "revenue_total": revenue_total,
                "revenue_today": revenue_today,
            },
            "orders_by_status": orders_by_status,
            "payments_by_status": payments_by_status,
            "deliveries_by_status": deliveries_by_status,
            "recent_orders": [
                {
                    "order_number": o.order_number,
                    "customer": o.customer.username,
                    "cylinder_type": o.cylinder_type.name,
                    "status": o.status,
                    "total_amount": o.total_amount,
                    "created_at": o.created_at,
                }
                for o in recent_orders
            ],
            "recent_transactions": [
                {
                    "order_number": p.order.order_number,
                    "customer": p.customer.username,
                    "method": p.method,
                    "amount": p.amount,
                    "status": p.status,
                    "created_at": p.created_at,
                }
                for p in recent_transactions
            ],
        })


class StaffActivityView(APIView):
    """
    GET /api/dashboard/staff-activity/
    Accountability view (proposal 4.12): what each staff member has been doing --
    orders handled, status changes made, deliveries assigned.
    """

    permission_classes = [IsStaffOrManagement]

    def get(self, request):
        staff_users = User.objects.filter(role__in=[User.Role.STAFF, User.Role.MANAGEMENT])
        data = []
        for staff in staff_users:
            data.append({
                "staff": staff.username,
                "role": staff.role,
                "orders_handled": Order.objects.filter(handled_by=staff).count(),
                "status_changes_made": OrderStatusHistory.objects.filter(changed_by=staff).count(),
                "deliveries_assigned": Delivery.objects.filter(assigned_to=staff).count(),
                "payments_confirmed": Payment.objects.filter(confirmed_by=staff).count(),
            })
        return Response(data)
