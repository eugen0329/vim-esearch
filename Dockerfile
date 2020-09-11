FROM debian:bullseye-slim AS build

WORKDIR /app

COPY Gemfile* spec/support/provision/ /app/
RUN set -eux;                                   \
    apt-get update; apt-get install -y ansible; \
    ansible-playbook site.yml

ENTRYPOINT ["/bin/bash", "--login", "-c"]
CMD ["bash"]
