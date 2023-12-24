#!/bin/bash

echo "Containers Starting ...."

if [ "$CONTAINER_ENGINE" == "k8s" ]; then
  echo "Create .env secrets"
  cat /app/.env.dir/secrets | base64 -d > .env
 # export $(cat /initcontainer/.env | xargs)
fi

PROCESS_TYPE=$1

if [ "$PROCESS_TYPE" = "bash" ]; then
  bash

elif [ "$PROCESS_TYPE" = "server" ]; then
  if [ "$ENVIRONMENT" = "local" ]; then
    cd /app/app
    python manage.py runserver 0.0.0.0:20001
  else
    uwsgi --http 0.0.0.0:20001 --module config.wsgi:application --processes 4 --threads 2 \
          --listen 4096 --buffer-size 32768 --enable-threads --vacuum \
          --logto /var/log/app/uwsgi.log --log-4xx --log-5xx \
          --log-slow --log-x-forwarded-for
  fi

elif [ "$PROCESS_TYPE" = "worker" ]; then
  celery -A config worker --loglevel=info -f /var/log/app/celery.log

elif [ "$PROCESS_TYPE" = "beat" ]; then
  celery -A config beat -l info -f /var/log/app/celery_beat.log

elif [ "$PROCESS_TYPE" = "makemigrations" ]; then
  python manage.py makemigrations --noinput

elif [ "$PROCESS_TYPE" = "migrate" ]; then
  python manage.py migrate --noinput

elif [ "$PROCESS_TYPE" = "superuser" ]; then
  DJANGO_SUPERUSER_USERNAME=${DJANGO_SUPERUSER_USERNAME} \
  DJANGO_SUPERUSER_PASSWORD=${DJANGO_SUPERUSER_PASSWORD} \
  DJANGO_SUPERUSER_EMAIL=${DJANGO_SUPERUSER_EMAIL} \
  python manage.py createsuperuser --noinput

elif [ "$PROCESS_TYPE" = "collectstatic" ]; then
  python manage.py collectstatic --noinput
fi

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
