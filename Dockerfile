FROM python:3.9

LABEL maintainer="mhrznamn <mhrznamn068@gmail.com>"

ENV USER=app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED=1

USER root

ENV TZ=Asia/Kathmandu
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update && apt install -y vim telnet build-essential curl libpq-dev --no-install-recommends \
    && useradd -m ${USER} \
    && mkdir -p /var/log/app /app /app/static /app/media \
    && chown -R ${USER}: /app /app/static /app/media \
    && chown -R ${USER}: /var/log/app

RUN python -m pip install --upgrade pip

WORKDIR /app/

COPY ./app/requirements.txt ./requirements.txt

RUN pip install -r ./requirements.txt

RUN ln -sf /dev/stdout /var/log/app/uwsgi.log

COPY ./app /app
COPY ./.helpers/scripts/start.sh /app
RUN chmod +x ./start.sh && chown -R ${USER}: /app

USER ${USER}
ENV PATH="/home/${USER}/.local/bin:$PATH"

ENTRYPOINT [ "./start.sh" ]

EXPOSE 20001

RUN wget -q https://static.snyk.io/cli/latest/snyk-linux && mv ./snyk-linux ./snyk && chmod +x ./snyk
