FROM ruby:2.2

LABEL author="Simon Wiles <simon.wiles@stanford.edu>"
EXPOSE 3000

ARG APP_DIR
WORKDIR ${APP_DIR}

RUN apt-get update -qq && \
	apt-get install -y --no-install-recommends postgresql-client nodejs nodejs-legacy npm && \
	rm -rf /var/lib/apt/lists/* && \
	git clone -b 2020-maintenance https://github.com/sul-cidr/al.git --depth 1 . && \
    bundle install --without deployment development test && \
    gem install passenger && \
    npm install --unsafe-perm

COPY authorial_final.sql.bz2 ${APP_DIR}
COPY .env ${APP_DIR}

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

COPY runserver.sh /usr/bin/
RUN chmod +x /usr/bin/runserver.sh
CMD ["runserver.sh"]
