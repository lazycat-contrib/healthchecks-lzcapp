#!/bin/sh
# Create the first Healthchecks superuser, once.
#
# Healthchecks' own run.sh only runs migrations and starts gunicorn; it never
# creates an account. This script runs before it and seeds a superuser from the
# deploy params, then lets the stock entrypoint take over.
set -eu

: "${HC_ADMIN_EMAIL:?HC_ADMIN_EMAIL is required}"
: "${HC_ADMIN_PASSWORD:?HC_ADMIN_PASSWORD is required}"

APP_DIR=/opt/healthchecks

cd "$APP_DIR"

# Wait for the database, then make sure the schema exists.
i=0
while [ "$i" -lt 60 ]; do
    if ./manage.py migrate --noinput >/dev/null 2>&1; then
        break
    fi
    i=$((i + 1))
    sleep 2
done

# Prefer the built-in createsuperuser --noinput path (uses DJANGO_SUPERUSER_*).
if ./manage.py createsuperuser --noinput --email "$HC_ADMIN_EMAIL" 2>/dev/null; then
    echo "[healthchecks] superuser created"
else
    echo "[healthchecks] superuser already exists (or creation skipped)"
fi

# Ensure the password matches the deploy param on every start (idempotent).
./manage.py shell -c "
from django.contrib.auth import get_user_model
U = get_user_model()
u = U.objects.filter(email__iexact='$HC_ADMIN_EMAIL').first()
if u is None:
    u = U.objects.create_superuser(email='$HC_ADMIN_EMAIL', password='$HC_ADMIN_PASSWORD')
else:
    u.set_password('$HC_ADMIN_PASSWORD')
    u.is_staff = True
    u.is_superuser = True
    u.save()
print('[healthchecks] admin ready:', u.email)
" || echo "[healthchecks] warning: could not sync admin password"

exec /opt/healthchecks/run.sh
