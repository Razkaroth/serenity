FROM node:20

RUN npm install -g gulp-cli mocha

WORKDIR /usr/src/habitica
COPY package.json package-lock.json ./
COPY . /usr/src/habitica
COPY config.json.example config.json

RUN npm install
RUN npm run postinstall

# Vite reads BASE_URL while producing the browser bundle.
ENV BASE_URL=http://serenity:9001
RUN npm run client:build
RUN gulp build:prod
