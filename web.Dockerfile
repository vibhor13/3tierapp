FROM  node:stretch-slim
EXPOSE 3000
WORKDIR /home/node/web/
COPY web/ /home/node/web/
RUN  apt-get update \
     && apt-get install strace netcat iputils-ping curl procps -y \
     && npm install
ENTRYPOINT ["npm","start"]