# Matchify website (Vite + React) — static build served by nginx.
#
# Cloudflare Pages does not need this image: it builds the site from git
# (build command `yarn ui:build`, output directory `dist`, root `frontend`).
# Use this image for container hosts (e.g. Cloudflare Containers, Render, Fly)
# or to run the production build locally:
#
#   docker build -t matchify-frontend ./frontend
#   docker run -p 8080:8080 matchify-frontend

# ---- build ----
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json yarn.lock .yarnrc ./
RUN yarn install --frozen-lockfile --non-interactive
COPY . .
RUN yarn ui:build

# ---- serve ----
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ >/dev/null || exit 1
