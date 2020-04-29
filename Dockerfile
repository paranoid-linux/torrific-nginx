FROM alpine


RUN apk update
RUN apk add --no-cache bash nginx tor


WORKDIR /git/hub/paranoid-linux/torrific-nginx
COPY . ./


ENTRYPOINT ["bash"]
CMD ["./torrific-nginx-server.sh"]
