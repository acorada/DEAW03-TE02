# Creamos la imagen a partir de ubuntu versión 18.04
FROM ubuntu:latest

# Damos información sobre la imagen que estamos creando
LABEL \
	version="1.0" \
	description="Ubuntu + Apache2 + virtual host + proftpd + ssl + ssh + git" \
	creationDate="15-01-2023" \
	maintainer="Alberto Corada <acorada@birt.eus>"

# Instalamos aplicaciones necesarias
RUN \
	apt-get update \
	&& apt-get -y install nano \
	&& apt-get -y install apache2 \
	&& apt-get -y install proftpd \
	&& apt-get -y install openssl \
	&& apt-get -y install ssh \
	&& apt-get -y install git


# Copiamos el index al directorio por defecto del servidor Web
COPY http/index1.html http/index2.html http/sitio1.conf http/sitio2.conf http/sitio1.key http/sitio1.cer /
# Copiamos los archivos para el ftp
COPY ftp/proftpd.conf ftp/tls.conf ftp/proftpd.crt ftp/proftpd.key /
# Copiamos deploy key de git
COPY git/id_rsa /
# Copiamos archivo configuracion ssh
COPY ssh/sshd_config /

# Comandos para cargar configuracion http
RUN \
	mkdir /var/www/html/sitio1 /var/www/html/sitio2 \
	&& mv /index1.html /var/www/html/sitio1/index.html \
	&& mv /index2.html /var/www/html/sitio2/index.html \
	&& mv /sitio1.conf /etc/apache2/sites-available \
	&& a2ensite sitio1.conf \
	&& mv /sitio2.conf /etc/apache2/sites-available \
	&& a2ensite sitio2.conf \
	&& mv /sitio1.key /etc/ssl/private \
	&& mv /sitio1.cer /etc/ssl/certs \
	&& a2enmod ssl \
	&& a2ensite default-ssl.conf

# Comandos para cargar configuracion ftp
RUN \
	mv /proftpd.conf /etc/proftpd/proftpd.conf \
	&& mv /tls.conf /etc/proftpd/tls.conf \
	&& mv /proftpd.crt /etc/ssl/certs/proftpd.crt \
	&& mv /proftpd.key /etc/ssl/private/proftpd.key

# Comandos para crear usuarios 
RUN useradd alberto1 -m -d /var/www/html/sitio1 -p $(openssl passwd -1 1234) -s /usr/sbin/nologin
RUN useradd alberto2 -m -d /var/www/html/sitio2 -p $(openssl passwd -1 1234) \
	&& echo "alberto2" >> /etc/ftpusers 

# Comandos para cargar contenido de git con deploy key
RUN mkdir ~/.ssh \
	&& chmod 700 ~/.ssh \
	&& mv /id_rsa ~/.ssh/ \
	&& chmod 600 ~/.ssh/id_rsa \
	&& touch ~/.ssh/known_hosts \
	&& ssh-keyscan github.com >> ~/.ssh/known_hosts \
	&& ssh-keygen -l -f ~/.ssh/id_rsa \
	&& git clone git@github.com:deaw-birt/deaw03-te1-ftp-anonimo.git /srv/ftp/git

# Comando para configurar ssh
RUN mv /sshd_config /etc/ssh/

# Indicamos los puertos que utiliza la imagen
EXPOSE 80
EXPOSE 443
EXPOSE 21
EXPOSE 22
EXPOSE 50000-50030
