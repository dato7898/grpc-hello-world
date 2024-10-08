# Используйте официальный образ Golang
FROM golang:1.21 AS builder

# Установите необходимые пакеты
RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Установите плагины protoc-gen-go и protoc-gen-go-grpc
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Добавьте путь к установленным плагинам в PATH
ENV PATH="/go/bin:${PATH}"

# Установите рабочую директорию
WORKDIR /app

# Set target platform
ENV GOOS=linux GOARCH=amd64

# Копируйте go.mod и go.sum и скачайте зависимости
COPY go.mod go.sum ./
RUN go mod download

# Копируйте остальные файлы проекта
COPY . .

# Сгенерируйте код из .proto файла
RUN protoc --go_out=. --go-grpc_out=. proto/helloworld.proto

# Соберите бинарный файл
RUN go build -o greeter ./main.go

# Убедитесь, что файл исполняемый
RUN chmod +x greeter

# Используйте легковесный образ для запуска приложения
FROM alpine:latest

# Установите рабочую директорию
WORKDIR /app

# Скопируйте бинарный файл из образа сборки
COPY --from=builder /app/greeter .

# Укажите порт, который будет использоваться
EXPOSE 50051

# Запустите приложение
CMD ["./greeter"]
