# Dockerfile for Mix & Mingle Firebase Functions (Node 20)
FROM node:20-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --production

COPY . .

RUN npm run build

CMD ["npm", "run", "serve"]
