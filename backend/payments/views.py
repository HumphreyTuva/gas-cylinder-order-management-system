import logging
import uuid

from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsOwnerOrStaffOrManagement, IsStaffOrManagement
from notifications.services import notify_payment_status_change
from orders.models import Order
from . import mpesa
from .models import Payment
from .serializers import (
    InitiateCardPaymentSerializer,
    InitiateMpesaPaymentSerializer,
    ManualPaymentConfirmationSerializer,
    PaymentSerializer,
)
from .utils import InvalidPhoneNumberError, normalize_kenyan_phone_number

logger = logging.getLogger(__name__)


class PaymentViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Read-only listing/retrieval of payment records.
    Customers see their own; staff/management see all.
    Actual payment creation happens via InitiateMpesaPaymentView / InitiateCardPaymentView
    so that the correct gateway workflow (STK push vs card token) is enforced.
    """

    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrStaffOrManagement]

    def get_queryset(self):
        user = self.request.user
        qs = Payment.objects.select_related("order", "customer")
        if user.is_staff_member or user.is_management:
            return qs
        return qs.filter(customer=user)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated, IsStaffOrManagement])
    def confirm(self, request, pk=None):
        """Staff can manually confirm/reject a payment (e.g. cash fallback, or M-Pesa callback failure)."""
        payment = self.get_object()
        serializer = ManualPaymentConfirmationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payment.status = serializer.validated_data["status"]
        ref = serializer.validated_data.get("transaction_reference")
        if ref:
            payment.transaction_reference = ref
        payment.confirmed_by = request.user
        payment.save(update_fields=["status", "transaction_reference", "confirmed_by", "updated_at"])
        notify_payment_status_change(payment)
        return Response(PaymentSerializer(payment).data)


class InitiateMpesaPaymentView(APIView):
    """POST /api/payments/mpesa/initiate/ -- triggers STK push prompt to customer's phone."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = InitiateMpesaPaymentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = _get_owned_order_or_404(request, serializer.validated_data["order"])

        if order.payments.filter(status=Payment.Status.SUCCESSFUL).exists():
            return Response(
                {"detail": "This order has already been paid for."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            phone_number = normalize_kenyan_phone_number(serializer.validated_data["phone_number"])
        except InvalidPhoneNumberError as exc:
            return Response({"phone_number": [str(exc)]}, status=status.HTTP_400_BAD_REQUEST)

        payment = Payment.objects.create(
            order=order,
            customer=request.user,
            amount=order.total_amount,
            method=Payment.Method.MPESA,
            mpesa_phone_number=phone_number,
        )

        try:
            result = mpesa.initiate_stk_push(
                phone_number=phone_number,
                amount=order.total_amount,
                account_reference=order.order_number,
                transaction_desc=f"Payment for order {order.order_number}",
            )
            payment.mpesa_checkout_request_id = result.get("CheckoutRequestID")
            payment.save(update_fields=["mpesa_checkout_request_id"])
            return Response(
                {"detail": "STK push sent. Ask the customer to enter their M-Pesa PIN.", "payment": PaymentSerializer(payment).data},
                status=status.HTTP_202_ACCEPTED,
            )
        except Exception as exc:  # noqa: BLE001 -- surface gateway errors without leaking internals
            logger.exception("M-Pesa STK push failed")
            payment.status = Payment.Status.FAILED
            payment.save(update_fields=["status"])
            return Response({"detail": "Failed to initiate M-Pesa payment.", "error": str(exc)}, status=status.HTTP_502_BAD_GATEWAY)


class MpesaCallbackView(APIView):
    """
    Public webhook: POST /api/payments/mpesa/callback/
    Registered as CallBackURL with Safaricom Daraja. Not authenticated (Safaricom
    calls this directly) -- in production this endpoint should be restricted to
    Safaricom's IP range at the network/firewall level.
    """

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        body = request.data.get("Body", {}).get("stkCallback", {})
        checkout_request_id = body.get("CheckoutRequestID")
        result_code = body.get("ResultCode")

        try:
            payment = Payment.objects.get(mpesa_checkout_request_id=checkout_request_id)
        except Payment.DoesNotExist:
            logger.warning("M-Pesa callback for unknown CheckoutRequestID: %s", checkout_request_id)
            return Response({"ResultCode": 0, "ResultDesc": "Accepted"})

        if result_code == 0:
            metadata = {item["Name"]: item.get("Value") for item in body.get("CallbackMetadata", {}).get("Item", [])}
            payment.status = Payment.Status.SUCCESSFUL
            payment.transaction_reference = metadata.get("MpesaReceiptNumber", str(uuid.uuid4()))
        else:
            payment.status = Payment.Status.FAILED if result_code != 1032 else Payment.Status.CANCELLED
        payment.save(update_fields=["status", "transaction_reference", "updated_at"])
        notify_payment_status_change(payment)

        return Response({"ResultCode": 0, "ResultDesc": "Accepted"})


class InitiateCardPaymentView(APIView):
    """
    POST /api/payments/card/initiate/
    Expects a payment_token already produced client-side by a card gateway SDK
    (e.g. Stripe/Flutterwave/Paystack) -- raw card numbers never reach this API.
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = InitiateCardPaymentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = _get_owned_order_or_404(request, serializer.validated_data["order"])

        if order.payments.filter(status=Payment.Status.SUCCESSFUL).exists():
            return Response(
                {"detail": "This order has already been paid for."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        payment = Payment.objects.create(
            order=order,
            customer=request.user,
            amount=order.total_amount,
            method=Payment.Method.CARD,
            card_gateway_reference=serializer.validated_data["payment_token"],
        )

        # TODO: call the real card gateway's charge API here using
        # payment_token, then update `payment.status` from its response.
        # Left as a stub since the proposal does not name a specific gateway.
        return Response(
            {"detail": "Card payment initiated.", "payment": PaymentSerializer(payment).data},
            status=status.HTTP_202_ACCEPTED,
        )


def _get_owned_order_or_404(request, order_id):
    from django.shortcuts import get_object_or_404
    qs = Order.objects.all() if (request.user.is_staff_member or request.user.is_management) else Order.objects.filter(customer=request.user)
    return get_object_or_404(qs, id=order_id)
