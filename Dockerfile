FROM openjdk:17-jdk-alpine AS build
RUN apk add maven
COPY src /build/src
COPY pom.xml /build/
WORKDIR /build
RUN mvn package -DskipTests
RUN mv /build/target/spring-rest-mysql*.jar /build/target/spring-rest-mysql.jar

FROM gcr.io/distroless/java17-debian11
COPY --from=build /build/target/spring-rest-mysql.jar /spring-rest-mysql.jar
CMD ["/spring-rest-mysql.jar"]
