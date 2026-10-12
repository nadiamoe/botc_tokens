FROM python:3.12-slim-bookworm

# Wand needs the ImageMagick shared library
RUN apt-get update \
    && apt-get install -y --no-install-recommends libmagickwand-6.q16-6 \
    && rm -rf /var/lib/apt/lists/*

# Debian blocks PDF output by default, and the group command writes PDFs
RUN sed -i '/policy.*coder.*none.*PDF/d' /etc/ImageMagick-6/policy.xml

# No .git in the build context, so setuptools-scm needs the version handed to it
ARG VERSION=0.0.0
ENV SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION}

WORKDIR /app
COPY pyproject.toml README.md ./
COPY src ./src
RUN pip install --no-cache-dir .

WORKDIR /work

ENTRYPOINT ["botc_tokens"]
