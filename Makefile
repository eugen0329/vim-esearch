DOCKER_RUN = docker run --rm -v $$PWD:/app -it esearch
DOCKER_BUILD = docker run --rm -v $$PWD:/app -it esearch

all: testing-image serializer

provision-host:
	ansible-playbook spec/support/provision/site.yml

build-testing-image:
	docker build -t esearch -f spec/support/provision/Dockerfile .

build-serializer: spec/support/lib/viml_value/lexer.rb spec/support/lib/viml_value/parser.rb

%.rb: %.rl
	$(DOCKER_RUN) ragel -e -L -F0 -R -o $@ $<

%.rb: %.y
	$(DOCKER_RUN) racc --output-file=$@ $<

.PHONY: serializer build-testing-image provision-host
