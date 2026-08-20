"""
Normalizes the many ways people type Kenyan phone numbers into the single
254XXXXXXXXX format Safaricom's Daraja API requires.

Accepts, among others:
  254113631232
  0113631232
  011 363 1232
  07-00 155 600
  +254113631232
  700144200
"""
import re


class InvalidPhoneNumberError(ValueError):
    pass


def normalize_kenyan_phone_number(raw: str) -> str:
    if not raw:
        raise InvalidPhoneNumberError("Phone number is required.")

    digits = re.sub(r"\D", "", raw)  # strip spaces, dashes, +, parentheses, etc.

    if digits.startswith("254") and len(digits) == 12:
        return digits
    if digits.startswith("0") and len(digits) == 10:
        return "254" + digits[1:]
    if len(digits) == 9:
        return "254" + digits

    raise InvalidPhoneNumberError(
        f"'{raw}' doesn't look like a valid Kenyan phone number. "
        "Try formats like 0712345678 or 254712345678."
    )
