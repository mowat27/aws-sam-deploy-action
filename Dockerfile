FROM python:3.8-slim-buster

LABEL maintainer="Adrian Mowat <adrian.mowat@gmail.com>"

RUN pip install aws-sam-cli pipenv

COPY entrypoint.sh /usr/local/bin/
VOLUME "/code"
WORKDIR "/code"

ENTRYPOINT [ "entrypoint.sh" ]