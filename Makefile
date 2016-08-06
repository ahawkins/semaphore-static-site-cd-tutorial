IMAGE:=slashdeploy/static-site-tutorial
DOCKER:=tmp/docker

.PHONY: check
check:
	docker --version > /dev/null
	ansible --version > /dev/null
	aws --version > /dev/null

tmp:
	mkdir -p $@

.PHONY: init
init: | tmp
	docker build -t middleman -f Dockerfile.init .
	docker create -it -w /data middleman \
		middleman init > tmp/init_container
	docker start -ai $$(cat tmp/init_container)
	@docker cp $$(cat tmp/init_container):/data - | tar xf - -C $(CURDIR) --strip-components=1 > /dev/null
	@docker stop $$(cat tmp/init_container) > /dev/null
	@docker rm -v $$(cat tmp/init_container) > /dev/null
	@rm tmp/init_container

.PHONY: dist
dist: Gemfile.lock | tmp
	mkdir -p build
	docker build -t $(IMAGE) .
	docker create \
		-e MIDDLEMAN_MINIFY_JS \
		-e MIDDLEMAN_MINIFY_CSS \
		-e MIDDLEMAN_HASH_ASSETS \
		$(IMAGE)
		middleman build > tmp/dist_container
	docker start $$(cat tmp/dist_container)
	@docker cp $$(cat tmp/dist_container):/build - | tar xf - -C build --strip-components=1 > /dev/null
	@docker stop $$(cat tmp/dist_container) > /dev/null
	@docker rm -v $$(cat tmp/dist_container) > /dev/null
	@rm tmp/dist_container

.PHONY: test-cloudformation
test-cloudformation:
	aws --region eu-west-1 cloudformation \
		validate-template --template-body file://cloudformation.json

.PHONY: deploy
deploy:
	aws --region $(REGION) s3 sync build/ s3://$(BUCKET)

.PHONY: clean
clean:
	rm -rf $(DOCKER) tmp build
