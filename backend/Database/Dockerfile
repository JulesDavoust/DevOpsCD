FROM mysql:latest

ENV MYSQL_ROOT_PASSWORD=CloudSoftware_#2025!
ENV MYSQL_DATABASE=clouddatabase
ENV MYSQL_USER=admin
ENV MYSQL_PASSWORD=CloudSoftware2025!

COPY ./init.sql /docker-entrypoint-initdb.d/

EXPOSE 3306

CMD ["mysqld"]
