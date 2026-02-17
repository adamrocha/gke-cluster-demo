FROM nginx:1.28.2-alpine-slim

# Install dependencies, create directories, and set up non-root user
RUN apk add --no-cache openssl=3.5.5-r0 && \
    mkdir -p /var/cache/nginx /var/run /run /etc/nginx/ssl && \
    addgroup -g10001 -S nginx-app && \
    adduser -S -D -H -u10001 -h /var/cache/nginx -s /sbin/nologin -G nginx-app -g nginx-app nginx-app

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Copy static content and config
COPY index.html /usr/share/nginx/html/index.html
COPY nginx.conf /etc/nginx/nginx.conf

# Set permissions and ownership
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chown -R nginx-app:nginx-app /var/cache/nginx /var/run /run /etc/nginx/ssl /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=5m --timeout=3s CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Expose non-privileged ports
EXPOSE 8080 8443

# Set working directory
WORKDIR /usr/share/nginx/html

# Switch to non-root user
USER nginx-app

# Start with entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]