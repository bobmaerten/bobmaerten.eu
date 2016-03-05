FROM nginx
ADD build /usr/share/nginx/html/
RUN rm -rf /usr/share/nginx/html/.git
COPY nginx-default.conf /etc/nginx/conf.d/default.conf
