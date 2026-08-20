"""
Notification creation + Firebase Cloud Messaging (FCM) push delivery.

Setup:
  1. Create a Firebase project, generate a service-account JSON key
     (Project settings -> Service accounts -> Generate new private key).
  2. Save it in the backend as `firebase-service-account.json` (path configurable
     via FIREBASE_CREDENTIALS_PATH in settings/.env) -- do NOT commit this file.
  3. `pip install firebase-admin` (already in requirements.txt).

This module always creates an in-app Notification record first (so the
in-app notification list works even if push delivery fails), then attempts
to also deliver a push notification via FCM if the user has a registered
device token.
"""
import logging

from django.conf import settings

logger = logging.getLogger(__name__)

_firebase_app = None


def _get_firebase_app():
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app
    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        _firebase_app = firebase_admin.initialize_app(cred)
    except Exception:  # noqa: BLE001
        logger.exception("Firebase Admin SDK not configured; push notifications disabled.")
        _firebase_app = False
    return _firebase_app


def send_push_notification(fcm_token: str, title: str, body: str, data: dict | None = None) -> bool:
    if not fcm_token:
        return False
    app = _get_firebase_app()
    if not app:
        return False
    try:
        from firebase_admin import messaging

        message = messaging.Message(
            token=fcm_token,
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
        )
        messaging.send(message)
        return True
    except Exception:  # noqa: BLE001
        logger.exception("Failed to send FCM push notification.")
        return False


def create_notification(*, user, notification_type, title, message, related_order=None):
    from .models import Notification

    notification = Notification.objects.create(
        user=user,
        notification_type=notification_type,
        title=title,
        message=message,
        related_order=related_order,
    )
    sent = send_push_notification(
        user.fcm_token,
        title,
        message,
        data={"type": notification_type, "order_id": str(related_order.id) if related_order else ""},
    )
    if sent:
        notification.sent_via_push = True
        notification.save(update_fields=["sent_via_push"])
    return notification


# --- Domain-specific helpers, called from orders/payments/deliveries views ---

_ORDER_STATUS_NOTIFICATIONS = {
    "confirmed": ("order_confirmation", "Order Confirmed", "Your order {order_number} has been confirmed."),
    "processing": ("order_processing", "Order Processing", "Your order {order_number} is now being processed."),
    "out_for_delivery": ("out_for_delivery", "Out for Delivery", "Your order {order_number} is out for delivery."),
    "delivered": ("delivery_completed", "Delivery Completed", "Your order {order_number} has been delivered. Thank you!"),
    "cancelled": ("order_cancelled", "Order Cancelled", "Your order {order_number} has been cancelled."),
    "rejected": ("order_cancelled", "Order Rejected", "Your order {order_number} has been rejected."),
    "failed_delivery": ("order_cancelled", "Delivery Failed", "Delivery for order {order_number} was unsuccessful. We will be in touch."),
}


def notify_order_status_change(order):
    entry = _ORDER_STATUS_NOTIFICATIONS.get(order.status)
    if not entry:
        return None
    notification_type, title, template = entry
    return create_notification(
        user=order.customer,
        notification_type=notification_type,
        title=title,
        message=template.format(order_number=order.order_number),
        related_order=order,
    )


def notify_payment_status_change(payment):
    if payment.status == "successful":
        title, message = "Payment Confirmed", f"We received your payment of {payment.amount} for order {payment.order.order_number}."
    elif payment.status == "failed":
        title, message = "Payment Failed", f"Your payment for order {payment.order.order_number} did not go through. Please try again."
    elif payment.status == "cancelled":
        title, message = "Payment Cancelled", f"Your payment for order {payment.order.order_number} was cancelled."
    else:
        return None

    notification = create_notification(
        user=payment.customer,
        notification_type="payment_confirmation",
        title=title,
        message=message,
        related_order=payment.order,
    )

    if payment.status == "successful":
        _notify_staff_of_payment(payment)

    return notification


def _notify_staff_of_payment(payment):
    """Lets staff/management know a customer has paid, so they can act on the
    order without having to check the dashboard proactively."""
    from django.contrib.auth import get_user_model

    User = get_user_model()
    staff_and_management = User.objects.filter(role__in=[User.Role.STAFF, User.Role.MANAGEMENT])
    method_label = "M-Pesa" if payment.method == "mpesa" else "Card"
    for staff_user in staff_and_management:
        create_notification(
            user=staff_user,
            notification_type="payment_confirmation",
            title="Payment Received",
            message=(
                f"{payment.customer.username} paid KES {payment.amount} via {method_label} "
                f"for order {payment.order.order_number}."
            ),
            related_order=payment.order,
        )


def notify_delivery_status_change(delivery):
    status_map = {
        "out_for_delivery": ("out_for_delivery", "Out for Delivery", "Your delivery for order {order_number} is on its way."),
        "delivered": ("delivery_completed", "Delivered", "Your order {order_number} has been delivered."),
        "failed": ("order_cancelled", "Delivery Failed", "We could not complete delivery for order {order_number}."),
    }
    entry = status_map.get(delivery.status)
    if not entry:
        return None
    notification_type, title, template = entry
    return create_notification(
        user=delivery.order.customer,
        notification_type=notification_type,
        title=title,
        message=template.format(order_number=delivery.order.order_number),
        related_order=delivery.order,
    )
