from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import transaction

from cylinders.models import CylinderType

User = get_user_model()


class Command(BaseCommand):
    help = "Seed initial cylinder catalogue and demo management/staff/customer accounts."

    @transaction.atomic
    def handle(self, *args, **options):
        catalogue = [
            {"name": "6kg Gas Cylinder", "size_kg": 6, "purchase_price": 3500, "refill_price": 1200, "stock_quantity": 50},
            {"name": "13kg Gas Cylinder", "size_kg": 13, "purchase_price": 5500, "refill_price": 2200, "stock_quantity": 80},
            {"name": "22.5kg Gas Cylinder", "size_kg": 22.5, "purchase_price": 9500, "refill_price": 3600, "stock_quantity": 30},
            {"name": "50kg Gas Cylinder", "size_kg": 50, "purchase_price": 18500, "refill_price": 7800, "stock_quantity": 15},
        ]
        for entry in catalogue:
            obj, created = CylinderType.objects.update_or_create(name=entry["name"], defaults=entry)
            self.stdout.write(self.style.SUCCESS(f"{'Created' if created else 'Updated'} cylinder type: {obj.name}"))

        demo_accounts = [
            {"username": "admin_manager", "role": User.Role.MANAGEMENT, "phone_number": "0700000001", "password": "ManagePass123!"},
            {"username": "staff_john", "role": User.Role.STAFF, "phone_number": "0700000002", "password": "StaffPass123!"},
            {"username": "customer_jane", "role": User.Role.CUSTOMER, "phone_number": "0700000003", "password": "CustomerPass123!"},
        ]
        for entry in demo_accounts:
            password = entry.pop("password")
            user, created = User.objects.get_or_create(username=entry["username"], defaults=entry)
            if created:
                user.set_password(password)
                if entry["role"] == User.Role.MANAGEMENT:
                    user.is_staff = True
                    user.is_superuser = True
                user.save()
                self.stdout.write(self.style.SUCCESS(f"Created demo user: {user.username} / {password} (role={user.role})"))
            else:
                self.stdout.write(f"Demo user already exists: {user.username}")

        self.stdout.write(self.style.SUCCESS("Seeding complete."))
