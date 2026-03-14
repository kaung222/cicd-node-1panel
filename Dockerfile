# Build stage
FROM node:alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
# Harden npm networking and use deterministic installs
 RUN npm config set registry https://registry.npmjs.org \
 && npm config set fetch-retries 5 \
 && npm config set fetch-retry-factor 2 \
 && npm config set fetch-retry-maxtimeout 600000 \
 && npm config set fetch-timeout 600000 \
 && npm ci --no-audit --no-fund --progress=false

# Copy the application source code
COPY . .
# Build the application
RUN npm run build

# Runtime stage
FROM node:alpine
# Set the working directory inside the container
WORKDIR /app

# Copy only necessary files from the build stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# Install only production dependencies deterministically
RUN npm ci --only=production --no-audit --no-fund --progress=false

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["node","dist/src/main.js"]