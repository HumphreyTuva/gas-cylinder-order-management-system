from django.urls import path

from .views import DashboardSummaryView, StaffActivityView

urlpatterns = [
    path("summary/", DashboardSummaryView.as_view(), name="dashboard-summary"),
    path("staff-activity/", StaffActivityView.as_view(), name="dashboard-staff-activity"),
]
