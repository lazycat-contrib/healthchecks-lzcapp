# Healthchecks (LazyCat LPK)

Cron job and background task monitoring.

- Upstream: https://github.com/healthchecks/healthchecks
- Image: `healthchecks/healthchecks:v5.0.3` (mirror mode, digest-matched)
- License: BSD-3-Clause (full text in `content/licenses/LICENSE`)
- Containers: Healthchecks + PostgreSQL 16 + Redis 7

## Notes

- The stock `run.sh` only runs `manage.py migrate` and starts gunicorn — it never creates an
  account. A small wrapper (`content/create-admin.sh`) is used as the entrypoint: it waits for
  the schema, ensures a superuser from the deploy params, re-syncs the password on every start,
  then execs the original `run.sh`.
- `REGISTRATION_OPEN=False` — only the admin can add members.
- `SECRET_KEY` and the DB password come from platform stable secrets; admin email/password come
  from deploy params (password random by default).
- No mail service configured, so email alerts cannot be delivered; use webhooks/integrations
  instead.
- Data on `/lzcapp/var/{pgdata,redisdata}`.
- Not yet verified on a real device.
