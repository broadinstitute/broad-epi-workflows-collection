#Add dockerfile boilerplate for python 3.12
FROM python:3.12
RUN pip install --upgrade pip && pip install deeptools

LABEL maintainer = "Eugenio Mattei"
LABEL software = "deeptools"

