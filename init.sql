CREATE DATABASE test;
CREATE USER 'spring-user'@'%' IDENTIFIED BY 'secret';
GRANT ALL ON test.* TO 'spring-user'@'%';
