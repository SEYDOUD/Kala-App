FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

COPY pubspec.* ./

RUN flutter pub get

COPY . .

RUN flutter config --enable-web

EXPOSE 8080

CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]