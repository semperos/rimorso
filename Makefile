PATH	:= ./node_modules/.bin:${PATH}
coffees := $(wildcard src/*.coffee)
coffee	:= ./node_modules/.bin/coffee
api-docs-cmd := ./node_modules/.bin/codo
api-docs-dir := api-docs
literate-docs-cmd := ./node_modules/.bin/docco
literate-docs-dir := literate-docs
watch	:= ./script/watch
test	:= ./node_modules/.bin/testem ci

.PHONY : deps api-docs literate-docs docs clean-api-docs clean-literate-docs clean-docs clean build build-all test all install dist publish

deps:
	@echo "[x] Retrieving dependencies..."
	npm install
	npm prune

api-docs: $(coffees) clean-api-docs deps
	@echo "[x] Generating API documentation..."
	@$(api-docs-cmd) -n "Rimorso" -o $(api-docs-dir) --title "Rimorso Api Documentation" src/

literate-docs: $(coffees) clean-literate-docs deps
	@echo "[x] Generating annotated source documentation..."
	@$(literate-docs-cmd) -o $(literate-docs-dir) $(coffees)

docs: $(coffees) api-docs literate-docs
	@echo "[x] All documentation generated."

clean-api-docs:
	@echo "[x] Removing API documentation..."
	-rm -rf $(api-docs-dir)

clean-literate-docs:
	@echo "[x] Removing annotated source documentation..."
	-rm -rf $(literate-docs-dir)

clean-docs: clean-api-docs clean-literate-docs
	@echo "[x] All documentation removed."

clean: clean-docs
	@echo "[x] Removing compiled files..."
	-rm -rf lib/
	-rm -f test/*.js

build: deps
	@echo "[x] Compiling src and test CoffeeScript to JavaScript..."
	@$(coffee) -o lib/ -c src/
	@$(coffee) -o test/ -c src-test/

test: build
	@echo "[x] Running tests..."
	@$(test)

dev: clean deps
	@echo "[x] Starting development environment..."
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
