docker_run := docker run --rm -v $$PWD:/app -it esearch

all: testing-image serializer

host-provision:
	ansible-playbook spec/support/provision/site.yml

testing-image:
	docker build -t esearch -f spec/support/provision/Dockerfile .

serializer: spec/support/lib/viml_value/lexer.rb spec/support/lib/viml_value/parser.rb

%.rb: %.rl testing-image 
	$(docker_run) ragel -e -L -F0 -R -o $@ $<

%.rb: %.y testing-image
	$(docker_run) racc --output-file=$@ $<

.PHONY: serializer testing-image host-provision
