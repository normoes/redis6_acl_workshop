FROM redis:6.0.1-alpine3.11

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV REDIS_PASSWORD ""
ENV REDIS_MASTER_PASSWORD ""
ENV REDIS_AUTH ""
ENV REDIS_MASTER_AUTH ""

ENTRYPOINT ["/entrypoint.sh"]

CMD ["redis-server"]
