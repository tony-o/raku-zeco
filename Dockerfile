FROM tonyodell/rakudo-nightly:latest
COPY META6.json /tmp
RUN apt update \
 && apt install -y --no-install-recommends libpq-dev build-essential \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
RUN cd /tmp \
 && zef install --deps-only .

CMD ["raku", "-I.", "-e", "use Zeco; await start-server"]
