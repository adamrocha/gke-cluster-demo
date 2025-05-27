FROM nginx:alpine

# Create a non-root user and group
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser

# Prepare necessary directories and fix permissions
RUN mkdir -p /var/cache/nginx /var/run /run /usr/share/nginx/html && \
    chown -R appuser:appgroup /var/cache/nginx /var/run /run /usr/share/nginx/html

# Copy static content
COPY index.html /usr/share/nginx/html/index.html

# Health check for basic uptime monitoring
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1

# Run as non-root user
USER appuser

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
# Expose port 80
EXPOSE 80
# Expose port 443 for HTTPS (if needed)
EXPOSE 443
# Set the working directory
WORKDIR /usr/share/nginx/html
# Copy additional configuration files if needed
# COPY nginx.conf /etc/nginx/nginx.conf
# Copy SSL certificates if needed
# COPY cert.pem /etc/ssl/certs/cert.pem
# COPY key.pem /etc/ssl/private/key.pem
# Optionally, you can add a custom configuration file
# COPY custom.conf /etc/nginx/conf.d/custom.conf
# Optionally, you can add a custom index.html file
# COPY custom_index.html /usr/share/nginx/html/index.html
# Optionally, you can add a custom error page
# COPY custom_404.html /usr/share/nginx/html/404.html
# Optionally, you can add a custom favicon
# COPY favicon.ico /usr/share/nginx/html/favicon.ico
# Optionally, you can add a custom robots.txt file
# COPY robots.txt /usr/share/nginx/html/robots.txt
# Optionally, you can add a custom sitemap.xml file
# COPY sitemap.xml /usr/share/nginx/html/sitemap.xml        