# =======================
# Builder Stage
# =======================
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install required packages (including git)
RUN apk add --no-cache git

# Copy only package files to install dependencies
COPY package*.json ./

# Install only production dependencies
RUN npm install --omit=dev && npm cache clean --force

# =======================
# Production Stage
# =======================
FROM node:18-alpine AS production

# Set working directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy node_modules from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy app source code
COPY . .

# Create necessary folders and set permissions
RUN mkdir -p logs uploads && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose the port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', res => process.exit(res.statusCode === 200 ? 0 : 1))" || exit 1

# Start the app
CMD ["npm", "start"]