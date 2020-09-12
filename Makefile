DOCKER_RUN = docker run --rm -v $$PWD:/app -it esearch
DOCKER_BUILD = docker run --rm -v $$PWD:/app -it esearch

all: testing-image serializer

host-provision:
	ansible-playbook spec/support/provision/site.yml

testing-image:
	docker build -t esearch -f spec/support/provision/Dockerfile .

serializer: spec/support/lib/viml_value/lexer.rb spec/support/lib/viml_value/parser.rb

%.rb: %.rl
	$(DOCKER_RUN) ragel -e -L -F0 -R -o $@ $<

%.rb: %.y
	$(DOCKER_RUN) racc --output-file=$@ $<

.PHONY: serializer testing-image host-provision
