from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsCustomer(BasePermission):
    message = "Only customers can perform this action."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_customer)


class IsStaffMember(BasePermission):
    message = "Only staff can perform this action."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_staff_member)


class IsManagement(BasePermission):
    message = "Only management/administrators can perform this action."

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_management)


class IsStaffOrManagement(BasePermission):
    message = "Only staff or management can perform this action."

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and (request.user.is_staff_member or request.user.is_management)
        )


class IsOwnerOrStaffOrManagement(BasePermission):
    """
    Object-level permission: customers may only access their own records
    (e.g. their own orders/payments); staff and management can access all.
    Assumes the model instance has a `customer` attribute pointing to a User,
    or is itself a User.
    """

    message = "You do not have permission to access this record."

    def has_object_permission(self, request, view, obj):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_staff_member or user.is_management:
            return True
        owner = getattr(obj, "customer", obj)
        return owner == user


class ReadOnlyOrStaffOrManagement(BasePermission):
    """Anyone authenticated can read (e.g. list cylinder catalogue); only staff/management may write."""

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        if request.method in SAFE_METHODS:
            return True
        return request.user.is_staff_member or request.user.is_management
