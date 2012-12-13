PATH := ./node_modules/.bin:${PATH}
coffees := $(wildcard src/*.coffee)

.PHONY : init clean-docs clean build build-all test dist publish

init:
	npm install

docs: $(coffees)
	docco $(coffees)

clean-docs:
	-rm -rf docs/

clean: clean-docs
	-rm -rf lib/ spec/*.js

build:
	coffee -o lib/ -c src/ && coffee -c spec/rimorso_spec.coffee

build-all: build docs

test:
	mocha spec/rimorso_spec.js

dist: clean init docs build test

publish: dist
	npm publish
