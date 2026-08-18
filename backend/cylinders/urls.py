from rest_framework.routers import DefaultRouter

from .views import CustomerCylinderViewSet, CylinderTypeViewSet

router = DefaultRouter()
router.register("types", CylinderTypeViewSet, basename="cylinder-type")
router.register("owned", CustomerCylinderViewSet, basename="customer-cylinder")

urlpatterns = router.urls
