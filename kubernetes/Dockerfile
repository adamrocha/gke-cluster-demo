FROM nginx:alpine
#RUN adduser -D -g 'appuser' appuser
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1
COPY index.html /usr/share/nginx/html/index.html
