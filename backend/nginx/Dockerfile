FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create directories for SSL certificates
RUN mkdir -p /etc/nginx/ssl

# Copy SSL certificates
COPY ./ssl/fullchain.pem /etc/nginx/ssl/
COPY ./ssl/privkey.pem /etc/nginx/ssl/

EXPOSE 3001

CMD ["nginx", "-g", "daemon off;"]
