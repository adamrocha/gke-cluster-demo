FROM nginx:alpine

# Install OpenSSL for certificate generation
RUN apk add --no-cache openssl

# Prepare necessary directories
RUN mkdir -p /var/cache/nginx /var/run /run /etc/nginx/ssl

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy static content and config
COPY index.html /usr/share/nginx/html/index.html
COPY nginx.conf /etc/nginx/nginx.conf

# Health check
HEALTHCHECK --interval=5m --timeout=3s CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Expose non-privileged ports
EXPOSE 8080 8443

# Set working directory
WORKDIR /usr/share/nginx/html

# Start with entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]