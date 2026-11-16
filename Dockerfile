FROM alpine:3.20
RUN apk add --no-cache bash
WORKDIR /app
COPY app/ /app/
RUN chmod +x /app/*.sh
HEALTHCHECK --interval=30s --timeout=5s CMD ["/app/health-check.sh"]
ENTRYPOINT ["/app/diagnostic.sh"]
CMD ["help"]
