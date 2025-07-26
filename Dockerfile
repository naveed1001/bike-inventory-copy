# =======================
# Builder Stage
# =======================
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy only package files to install dependencies
COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev && npm cache clean --force

# =======================
# Production Stage
# =======================
FROM node:18-alpine AS production

# Create app directory
WORKDIR /app

# Create non-root user for better security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy production node_modules from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy the rest of the application code
COPY . .

# Create necessary directories and set permissions
RUN mkdir -p logs uploads && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', res => process.exit(res.statusCode === 200 ? 0 : 1))" || exit 1

# Start the app
CMD ["npm", "start"]