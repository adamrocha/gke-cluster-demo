FROM nginx:alpine

# Create a non-root user and group
RUN addgroup -S -g 1000 appgroup && \
    adduser -S -u 1000 -G appgroup appuser

# Prepare necessary directories
RUN mkdir -p /var/cache/nginx /var/run /run /usr/share/nginx/html

# Copy static content and config
COPY --chown=1000:1000 index.html /usr/share/nginx/html/index.html
COPY --chown=1000:1000 nginx.conf /etc/nginx/nginx.conf

# Set correct permissions
RUN chown -R 1000:1000 /var/cache/nginx /var/run /run /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:8080/ || exit 1

# Run as non-root user
USER 1000:1000

# Expose non-privileged port
EXPOSE 8080

# Set working directory
WORKDIR /usr/share/nginx/html

# Disable default entrypoint
ENTRYPOINT []

# Start nginx with custom config
CMD ["nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
