DOCKER_RUN = docker run --rm -v $$PWD:/app -it esearch

all: testing-image serializer

.PHONY: login
login:
	$(DOCKER_RUN) bash

.PHONY: setup-host
setup-host:
	ansible-playbook spec/support/setup/site.yml

.PHONY: setup-testing-image
setup-testing-image:
	docker build -t esearch -f spec/support/setup/Dockerfile .

.PHONY: setup-serializer
setup-serializer: spec/support/lib/viml_value/lexer.rb spec/support/lib/viml_value/parser.rb

%.rb: %.rl
	$(DOCKER_RUN) ragel -e -L -F0 -R -o $@ $<

%.rb: %.y
	$(DOCKER_RUN) racc --output-file=$@ $<
