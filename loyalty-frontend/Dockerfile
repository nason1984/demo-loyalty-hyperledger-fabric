# File: loyalty-frontend/Dockerfile

# --- STAGE 1: Build ---
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application source code
COPY . .

# Build the React application for production
RUN npm run build

# --- STAGE 2: Serve ---
FROM nginx:stable-alpine

# Copy the build output to replace the default Nginx content.
COPY --from=builder /app/build /usr/share/nginx/html

# Copy our custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]