FROM ruby:2.7.0-buster

COPY Gemfile* spec/support/setup/ /
RUN set -eux;                                     \
    apt-get update; apt-get install -y ansible;   \
    ansible-playbook site.yml;                    \
    apt-get install -y xvfb;                      \
    rm -rf /var/lib/apt/lists/*; apt-get clean -y;

WORKDIR /app
ENV DISPLAY=:99
ENV LANG=C.UTF-8

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
