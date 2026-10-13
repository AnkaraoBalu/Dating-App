# Just2 API (NestJS + Prisma) — production image for Render.
#
# Build:  docker build -t just2-backend ./backend
# Run:    docker run -p 3000:3000 --env-file backend/.env just2-backend
#
# Render injects PORT; the app already reads PORT and binds to 0.0.0.0.
# Database migrations run on start (set RUN_MIGRATIONS=false to skip, e.g. if
# you use a Render pre-deploy command instead).

# ---- build: install all deps, generate Prisma client, compile ----
FROM node:22-bookworm-slim AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends openssl \
  && rm -rf /var/lib/apt/lists/*

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --non-interactive

COPY . .
# prisma.config.ts reads DB_URL when it loads; generating the client does not
# connect, so a placeholder URL is enough at build time.
RUN DB_URL="postgresql://build:build@localhost:5432/build" yarn backend:db:generate \
  && yarn backend:build

# ---- runtime ----
FROM node:22-bookworm-slim AS runtime
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends openssl tini \
  && rm -rf /var/lib/apt/lists/*
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=3000 \
    RUN_MIGRATIONS=true

# node_modules keeps the Prisma CLI so `prisma migrate deploy` can run here.
COPY --from=build --chown=node:node /app/package.json /app/prisma.config.ts ./
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/prisma ./prisma
COPY --from=build --chown=node:node /app/dist ./dist

USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/api/v1/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["tini", "--"]
CMD ["sh", "-c", "if [ \"$RUN_MIGRATIONS\" = \"true\" ]; then npx prisma migrate deploy; fi && exec node dist/src/main.js"]
