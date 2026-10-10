# syntax=docker/dockerfile:1

# --- Build stage ---
FROM node:22-alpine AS builder
WORKDIR /app

# Native deps required to compile better-sqlite3
RUN apk add --no-cache python3 make g++ sqlite libc6-compat

COPY package.json ./
RUN npm install

COPY . .
RUN npm run build

# --- Run stage ---
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NITRO_PRESET=node-server
ENV PORT=3000

COPY --from=builder /app/.output ./.output

EXPOSE 3000
CMD ["node", ".output/server/index.mjs"]
