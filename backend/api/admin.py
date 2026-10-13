from django.contrib import admin

from .models import Profile


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('email', 'name', 'user_type', 'lives', 'updated_at')
    search_fields = ('email', 'name', 'uid')
    readonly_fields = ('uid', 'updated_at')
