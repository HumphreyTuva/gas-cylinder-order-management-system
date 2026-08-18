from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id", "username", "first_name", "last_name", "email", "phone_number",
            "role", "default_delivery_address", "is_active_staff", "date_joined",
        ]
        read_only_fields = ["id", "role", "date_joined", "is_active_staff"]


class CustomerRegistrationSerializer(serializers.ModelSerializer):
    """Public self-registration endpoint. Always creates role=customer."""

    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            "id", "username", "first_name", "last_name", "email", "phone_number",
            "default_delivery_address", "password", "password_confirm",
        ]
        read_only_fields = ["id"]

    def validate(self, attrs):
        if attrs["password"] != attrs.pop("password_confirm"):
            raise serializers.ValidationError({"password_confirm": "Passwords do not match."})
        return attrs

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User(role=User.Role.CUSTOMER, **validated_data)
        user.set_password(password)
        user.save()
        return user


class StaffCreationSerializer(serializers.ModelSerializer):
    """Used by management to create staff or management accounts."""

    password = serializers.CharField(write_only=True, validators=[validate_password])

    class Meta:
        model = User
        fields = [
            "id", "username", "first_name", "last_name", "email", "phone_number",
            "role", "password",
        ]
        read_only_fields = ["id"]

    def validate_role(self, value):
        if value not in (User.Role.STAFF, User.Role.MANAGEMENT):
            raise serializers.ValidationError("Role must be 'staff' or 'management'.")
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class FCMTokenSerializer(serializers.Serializer):
    fcm_token = serializers.CharField(max_length=255)


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Adds role/user info to the JWT payload and login response."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["role"] = user.role
        token["username"] = user.username
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data["user"] = UserSerializer(self.user).data
        return data
