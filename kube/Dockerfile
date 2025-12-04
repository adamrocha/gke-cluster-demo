FROM nginx:1.28.0-alpine-slim

# Create a non-root user and group
RUN addgroup -S -g 10001 appgroup && \
    adduser -S -u 10001 -G appgroup appuser

# Prepare necessary directories
RUN mkdir -p /var/cache/nginx /var/run /run /usr/share/nginx/html

# Copy static content and config
COPY --chown=10001:10001 index.html /usr/share/nginx/html/index.html
COPY --chown=10001:10001 nginx.conf /etc/nginx/nginx.conf

# Set correct permissions
RUN chown -R 10001:10001 /var/cache/nginx /var/run /run /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:8080/ || exit 1

# Run as non-root user
USER 10001:10001

# Expose non-privileged port
EXPOSE 8080

# Set working directory
WORKDIR /usr/share/nginx/html

# Disable default entrypoint
ENTRYPOINT []

# Start nginx with custom config
CMD ["nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
