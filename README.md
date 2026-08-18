# Gas Cylinder Order Tracking and Management System

Full implementation of the system described in the proposal:
- **Backend**: Django + Django REST Framework + PostgreSQL + JWT auth + role-based permissions
- **Frontend**: Flutter (customer, staff, and management apps in one codebase, role-routed)
- **Payments**: M-Pesa (Daraja STK Push) + Card (gateway-agnostic, token-based)
- **Notifications**: Firebase Cloud Messaging (push) + in-app notification log

```
gas_cylinder_system/
  backend/    Django REST API — see backend/README.md
  frontend/   Flutter app     — see frontend/README.md
```

## Quick start

```bash
# 1. Backend
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # then edit DATABASE_URL, M-Pesa & Firebase settings
python manage.py migrate
python manage.py seed_demo_data   # demo accounts + cylinder catalogue
python manage.py runserver

# 2. Frontend (in a new terminal)
cd frontend
flutter create . --project-name gas_cylinder_app
flutter pub get
cp .env.example .env        # point API_BASE_URL at the backend above
flutterfire configure       # wires up real Firebase project
flutter run
```

Demo logins (created by `seed_demo_data`):

| Username | Password | Role |
|---|---|---|
| admin_manager | ManagePass123! | management |
| staff_john | StaffPass123! | staff |
| customer_jane | CustomerPass123! | customer |

## How this maps to the proposal

| Proposal section | Where it lives |
|---|---|
| 4.1 Customer registration/login | `backend/accounts`, `frontend/lib/screens/auth` |
| 4.2–4.3 Purchase / Refill | `backend/orders`, `frontend/lib/screens/customer/place_order_screen.dart` |
| 4.4 Order tracking (Pending → Delivered) | `backend/orders/models.py::Order.Status`, `frontend/lib/screens/customer/order_detail_screen.dart` |
| 4.5–4.6 Customer & cylinder records | `backend/accounts`, `backend/cylinders` |
| 4.7 Delivery management | `backend/deliveries`, `frontend/lib/screens/staff` |
| 4.8 Payment integration (M-Pesa/Card) | `backend/payments`, `frontend/lib/screens/shared/payment_screen.dart` |
| 4.9 Notifications | `backend/notifications` (FCM), `frontend/lib/services/push_notification_service.dart` |
| 4.10 Management dashboard | `backend/dashboard`, `frontend/lib/screens/management` |
| 4.11 Staff/user management | `backend/accounts/views.py::StaffManagementViewSet` |
| 4.12 Activity monitoring | `backend/orders/models.py::OrderStatusHistory`, `backend/dashboard/views.py::StaffActivityView` |

## What's stubbed for you to finish

- **Card payment gateway**: the API accepts a payment token; you need to pick a
  gateway (Stripe/Flutterwave/Paystack are common choices in Kenya) and wire up
  its Flutter SDK client-side.
- **Firebase project**: `flutterfire configure` + a service-account key on the
  backend are both needed for push notifications to actually deliver.
- **M-Pesa credentials**: sandbox keys from the Safaricom Daraja portal for
  testing; production Paybill/Till + go-live approval for real payments.
- **Section 7 future improvements** (reports, GPS tracking, WhatsApp, loyalty
  programmes) are intentionally out of scope for this first build, as the
  proposal describes them as phase-two additions.
