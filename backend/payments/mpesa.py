"""
M-Pesa Daraja API integration (STK Push / Lipa na M-Pesa Online).

Configure these in your environment / .env (see config/settings.py):
    MPESA_ENV                 = "sandbox" or "production"
    MPESA_CONSUMER_KEY
    MPESA_CONSUMER_SECRET
    MPESA_SHORTCODE           (Paybill/Till number)
    MPESA_PASSKEY
    MPESA_CALLBACK_URL        (publicly reachable HTTPS URL for payment confirmation)

This module isolates all Safaricom Daraja API calls so the rest of the app
never needs to know the transport details.
"""
import base64
import datetime

import requests
from django.conf import settings

SANDBOX_BASE_URL = "https://sandbox.safaricom.co.ke"
PRODUCTION_BASE_URL = "https://api.safaricom.co.ke"


def _base_url():
    return PRODUCTION_BASE_URL if settings.MPESA_ENV == "production" else SANDBOX_BASE_URL


def get_access_token() -> str:
    url = f"{_base_url()}/oauth/v1/generate?grant_type=client_credentials"
    response = requests.get(
        url,
        auth=(settings.MPESA_CONSUMER_KEY, settings.MPESA_CONSUMER_SECRET),
        timeout=30,
    )
    response.raise_for_status()
    return response.json()["access_token"]


def _password_and_timestamp():
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    raw = f"{settings.MPESA_SHORTCODE}{settings.MPESA_PASSKEY}{timestamp}"
    password = base64.b64encode(raw.encode()).decode()
    return password, timestamp


def initiate_stk_push(*, phone_number: str, amount, account_reference: str, transaction_desc: str) -> dict:
    """
    Triggers the STK push prompt on the customer's phone asking them to enter
    their M-Pesa PIN to authorize payment. Returns Safaricom's response, which
    includes CheckoutRequestID -- store this on the Payment record so the
    callback can be matched back to it.
    """
    access_token = get_access_token()
    password, timestamp = _password_and_timestamp()

    payload = {
        "BusinessShortCode": settings.MPESA_SHORTCODE,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": int(amount),
        "PartyA": phone_number,
        "PartyB": settings.MPESA_SHORTCODE,
        "PhoneNumber": phone_number,
        "CallBackURL": settings.MPESA_CALLBACK_URL,
        "AccountReference": account_reference,
        "TransactionDesc": transaction_desc,
    }
    response = requests.post(
        f"{_base_url()}/mpesa/stkpush/v1/processrequest",
        json=payload,
        headers={"Authorization": f"Bearer {access_token}"},
        timeout=30,
    )
    response.raise_for_status()
    return response.json()
