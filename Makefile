RUBY_IMAGE:=$(shell head -n 1 Dockerfile | cut -d ' ' -f 2)
IMAGE:=semaphore/middleman-cd
DOCKER:=tmp/docker

.PHONY: check
check:
	docker --version > /dev/null
	ansible --version > /dev/null

init: Dockerfile.init
	docker build -t middleman -f Dockerfile.init .
	docker run --rm  -it -v $(CURDIR):/data -w /data middleman \
		middleman init --skip-bundle

Gemfile.lock: Gemfile
	docker run --rm -v $(CURDIR):/data -w /data $(RUBY_IMAGE) \
		bundle package --all

$(DOCKER): Gemfile.lock
	docker build -t $(IMAGE) .
	mkdir -p $(@D)
	touch $@

.PHONY: dist
dist: $(DOCKER)
	docker run --rm -v $(CURDIR):/data -w /data \
		-e MIDDLEMAN_MINIFY_JS \
		-e MIDDLEMAN_MINIFY_CSS \
		-e MIDDLEMAN_CDN_HOST \
		$(IMAGE) \
		middleman build

.PHONY: test-cloudformation
test-cloudformation:
	aws --region eu-west-1 cloudformation \
		validate-template --template-body file://cloudformation/app.json

.PHONY: deploy
deploy:
	aws --region $(REGION) s3 sync build/ s3://$(BUCKET)

.PHONY: clean
clean:
	rm -rf $(DOCKER)
