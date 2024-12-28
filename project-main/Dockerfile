FROM golang:latest
WORKDIR /app

COPY ./webapi/ .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o /devops-prj-webapp

EXPOSE 9090

CMD ["/devops-prj-webapp"]