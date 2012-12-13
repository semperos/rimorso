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
	-rm -rf lib/

build:
	coffee -o lib/ -c src/

build-all: build test docs

test:
	mocha

dist: clean init docs build test

publish: dist
	npm publish
