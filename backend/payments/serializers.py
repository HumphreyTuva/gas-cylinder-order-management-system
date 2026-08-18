from rest_framework import serializers

from .models import Payment


class PaymentSerializer(serializers.ModelSerializer):
    order_number = serializers.CharField(source="order.order_number", read_only=True)
    customer_username = serializers.CharField(source="customer.username", read_only=True)

    class Meta:
        model = Payment
        fields = [
            "id", "order", "order_number", "customer", "customer_username", "amount", "method",
            "status", "transaction_reference", "mpesa_checkout_request_id", "mpesa_phone_number",
            "card_gateway_reference", "confirmed_by", "created_at", "updated_at",
        ]
        read_only_fields = [
            "id", "customer", "status", "transaction_reference", "mpesa_checkout_request_id",
            "confirmed_by", "created_at", "updated_at",
        ]


class InitiateMpesaPaymentSerializer(serializers.Serializer):
    order = serializers.UUIDField()
    phone_number = serializers.CharField(max_length=20)


class InitiateCardPaymentSerializer(serializers.Serializer):
    order = serializers.UUIDField()
    # In a real integration, the frontend would use the card gateway's SDK
    # (Stripe/Flutterwave/Paystack) to tokenize the card and pass only the
    # resulting token here -- raw card numbers should never touch this API.
    payment_token = serializers.CharField(max_length=255)


class ManualPaymentConfirmationSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=[Payment.Status.SUCCESSFUL, Payment.Status.FAILED, Payment.Status.CANCELLED])
    transaction_reference = serializers.CharField(required=False, allow_blank=True)
