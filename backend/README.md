# Gas Cylinder Order Tracking & Management — Backend

Django + Django REST Framework + PostgreSQL + JWT auth + role-based permissions +
M-Pesa (Daraja STK Push) + Card payments + Firebase Cloud Messaging.

## 1. Setup

```bash
cd backend
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# Edit .env: set DJANGO_SECRET_KEY, DATABASE_URL, M-Pesa + Firebase credentials
```

### PostgreSQL

Create the database referenced in `DATABASE_URL` (default below), or use Docker (see `docker-compose.yml`):

```bash
createdb gascylinder_db
# or
psql -c "CREATE USER gascylinder_user WITH PASSWORD 'gascylinder_pass';"
psql -c "CREATE DATABASE gascylinder_db OWNER gascylinder_user;"
```

### Firebase Cloud Messaging

1. Firebase Console → Project Settings → Service Accounts → Generate new private key.
2. Save the JSON as `backend/firebase-service-account.json` (already in `.gitignore`).

### M-Pesa Daraja

Get sandbox credentials from https://developer.safaricom.co.ke/ and fill in
`MPESA_CONSUMER_KEY`, `MPESA_CONSUMER_SECRET`, `MPESA_PASSKEY`, `MPESA_SHORTCODE`,
and `MPESA_CALLBACK_URL` (must be a publicly reachable HTTPS URL — use ngrok in dev).

## 2. Run

```bash
python manage.py migrate
python manage.py createsuperuser
python manage.py seed_demo_data   # optional: cylinder catalogue + demo accounts
python manage.py runserver
```

Demo accounts created by `seed_demo_data`:

| Username        | Password           | Role       |
|-----------------|---------------------|------------|
| admin_manager   | ManagePass123!      | management |
| staff_john      | StaffPass123!        | staff      |
| customer_jane   | CustomerPass123!     | customer   |

## 3. Docker (alternative)

```bash
docker compose up --build
```

## 4. API overview

Base URL: `http://localhost:8000/api/`

| Area | Endpoint | Notes |
|---|---|---|
| Auth | `POST /accounts/register/` | Public customer self-registration |
| Auth | `POST /accounts/login/` | Returns `access`, `refresh`, `user` (JWT) |
| Auth | `POST /accounts/login/refresh/` | Refresh access token |
| Auth | `GET/PATCH /accounts/me/` | Current user profile |
| Auth | `POST /accounts/fcm-token/` | Register device push token |
| Accounts | `GET/POST /accounts/staff/` | Management-only: manage staff accounts |
| Accounts | `GET /accounts/customers/` | Staff/management: browse customers |
| Cylinders | `GET/POST /cylinders/types/` | Catalogue (read: all, write: staff/mgmt) |
| Cylinders | `GET/POST /cylinders/owned/` | Customer's registered cylinders (for refills) |
| Orders | `GET/POST /orders/` | Create/list orders |
| Orders | `POST /orders/{id}/update_status/` | Staff/mgmt: move through status workflow |
| Orders | `POST /orders/{id}/assign_to_me/` | Staff claims an order |
| Orders | `POST /orders/{id}/cancel/` | Customer cancels while pending |
| Payments | `POST /payments/mpesa/initiate/` | Triggers STK push |
| Payments | `POST /payments/mpesa/callback/` | Safaricom webhook (public) |
| Payments | `POST /payments/card/initiate/` | Card payment (token-based) |
| Payments | `POST /payments/{id}/confirm/` | Staff manual confirmation |
| Deliveries | `GET/POST /deliveries/` , `.../assign/`, `.../mark_delivered/`, `.../mark_failed/` | |
| Notifications | `GET /notifications/`, `.../mark_read/`, `.../mark_all_read/` | |
| Dashboard | `GET /dashboard/summary/` | Management overview |
| Dashboard | `GET /dashboard/staff-activity/` | Accountability / activity monitoring |

All endpoints (except register/login/mpesa-callback) require:
`Authorization: Bearer <access_token>`

## 5. Order status workflow

```
Pending → Confirmed → Processing → Out for Delivery → Delivered
                                  ↘ Failed Delivery ↗
Pending → Rejected / Cancelled
```
Enforced server-side in `orders/serializers.py::OrderStatusUpdateSerializer`.

## 6. Roles & permissions

- **customer** — register, browse catalogue, place orders, pay, track own orders/deliveries/payments, receive notifications.
- **staff** — everything above for all customers, plus: update order status, assign/confirm deliveries, confirm payments manually.
- **management** — everything staff can do, plus: create/deactivate staff accounts, dashboard analytics, staff activity monitoring.

Enforced via `accounts/permissions.py` role-based permission classes on every viewset.
