SHELL := /bin/bash

next-semver:
	releasetool next-version --bump-patch > .next-version
	cat .next-version

.PHONY: git-tag
git-tag:
	releasetool generate-tag --tag-version=$(shell cat .next-version) 

.PHONY: git-release
git-release:
	releasetool generate-release --tag-version=$(shell cat .next-version) --distribute
	

