FROM node:alpine AS base


FROM base AS deps
WORKDIR /app
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN npm ci


FROM deps AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build


FROM base AS start
WORKDIR /app
COPY --from=builder /app/dist ./dist
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
USER node
EXPOSE 3000
CMD ["node", "./dist/index.js"]