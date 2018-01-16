FROM breather/node-base-builder:6.0-10 AS builder

FROM breather/node-base:6.0-10
  RUN apt-get update \
   && apt-get install --no-install-recommends -y \
        imagemagick \
        libfontconfig \
        netcat \
   && rm -rf /var/lib/apt/lists/*

  ARG NODE_ENV
  ENV BREATHER_ENV=${NODE_ENV:-production} \
      DB_RESTORE_IF_EMPTY=false \
      NODE_ENV=${NODE_ENV:-production}

  COPY . /app/
  COPY --from=builder /build/${NODE_ENV}/ /app/

  RUN if test $NODE_ENV = production; then \
        ./node_modules/.bin/coffee --compile . \
        ; \
        find . \
          -not \( -path ./.git -prune \) \
          -not \( -path ./assets -prune \) \
          -not \( -path ./data -prune \) \
          -not \( -path ./node_modules -prune \) \
          -not \( -path ./scripts -prune \) \
          -not -path ./app.coffee \
          -not -path ./commands.coffee \
          -not -path ./gulpfile.coffee \
          -name '*.coffee' \
          -exec rm {} \; \
        ; \
      fi

EXPOSE 3333 3334
CMD ["/app/.docker/runcmd"]
