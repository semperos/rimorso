PATH	:= ./node_modules/.bin:${PATH}
coffees := $(wildcard src/*.coffee)
test-coffees = := $(wildcard src=test/*_test.coffee)
coffee	:= ./node_modules/.bin/coffee
mocha	:= ./node_modules/.bin/mocha
watch	:= ./script/watch
test	:= ./node_modules/.bin/testem ci

.PHONY : deps clean-docs clean build build-all test all install dist publish

deps:
	@echo "[x] Retrieving dependencies..."
	npm install
	npm prune

docs: $(coffees)
	@echo "[x] Generating documentation..."
	docco $(coffees)

clean-docs:
	@echo "[x] Removing documentation..."
	-rm -rf docs/

clean: clean-docs
	@echo "[x] Removing compiled files..."
	-rm -rf lib/
	-rm -f test/*.js

build:
	@echo "[x] Compiling src and test CoffeeScript to JavaScript..."
	@$(coffee) -o lib/ -c src/
	@$(coffee) -o test/ -c src-test/

test: build
	@echo "[x] Running tests..."
	@$(test)

# Watches fs and calls 'build-all'
watch: clean
	@echo "[x] Starting watcher..."
	@$(watch)

build-all: build test docs

all: clean deps build-all

# Local deployment
install: all
	@echo "[x] Installing Rimorso locally..."
	npm install

# Remote deployment
publish: all
	@echo "[x] Publishing Rimorso to NPM..."
	npm publish
