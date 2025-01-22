FROM --platform=$TARGETPLATFORM node:lts-alpine AS base


FROM base AS devdeps
RUN mkdir -p /temp/dev
COPY package.json package-lock.json* /temp/dev/
RUN cd /temp/dev && npm i


FROM base AS proddeps
RUN mkdir -p /temp/prod
COPY package.json package-lock.json* /temp/prod/
RUN cd /temp/prod && npm i --omit-dev


FROM base AS builder
WORKDIR /app
COPY --from=devdeps /temp/dev/node_modules node_modules
COPY . .
RUN npx esbuild src/index.ts --bundle --outfile=dist/index.js --platform=node


FROM base AS start
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=proddeps /temp/prod/node_modules node_modules
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
USER node
EXPOSE 3000
HEALTHCHECK CMD wget --no-verbose --spider --tries=1 http://localhost:3000 || exit 1
CMD ["node", "dist/index.js"]