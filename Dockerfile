FROM php:8.2-apache

RUN a2enmod rewrite
RUN docker-php-ext-install mysqli

# Set Apache ServerName
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html

# Set working directory
WORKDIR /var/www/html

# Make script executable and use it
RUN chmod +x start.sh
CMD ["./start.sh"]

EXPOSE 80

