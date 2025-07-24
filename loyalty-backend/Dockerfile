# File: loyalty-backend/Dockerfile

# --- STAGE 1: Build ---
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go.mod and go.sum files (if exists)
COPY go.mod ./
COPY go.su[m] ./
# Download all dependencies and create go.sum if not exists
RUN go mod download && go mod tidy

# Copy the source code
COPY . .

# Build the application
# CGO_ENABLED=0 is important for a static binary
# -o /app/server creates the executable named 'server'
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /app/server ./

# --- STAGE 2: Run ---
FROM alpine:latest

WORKDIR /app

# Copy the executable from the builder stage
COPY --from=builder /app/server .

# Expose port 8080 to the outside world
EXPOSE 8080

# Command to run the executable
CMD ["./server"]