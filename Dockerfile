# ---------- Builder stage ----------
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
COPY frontend/package*.json ./frontend/
COPY . .
RUN npm ci \
  && npm ci --prefix frontend \
  && npm run build --prefix frontend

# ---------- Runtime stage ----------
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/backend ./backend
COPY --from=builder /app/frontend/dist ./frontend/dist
EXPOSE 5000
CMD ["node", "backend/server.js"]
