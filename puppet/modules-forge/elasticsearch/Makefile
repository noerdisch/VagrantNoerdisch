DISTRO ?= ubuntu-server-1404-x64
PE ?= false
STRICT_VARIABLES ?= yes

ifeq ($(PE), true)
	PE_VER ?= 3.8.3
	BEAKER_PE_VER := $(PE_VER)
	BEAKER_IS_PE := $(PE)
	export BEAKER_PE_VER
	export BEAKER_IS_PE
endif

.DEFAULT_GOAL := bundle

.PHONY: bundle
bundle:
	bundle update || true
	bundle install --path .vendor

.PHONY: clean
clean:
	bundle exec rake spec_clean
	bundle exec rake artifacts:clean
	rm -rf .bundle .vendor

.PHONY: clean-logs
clean-logs:
	rm -rf log

.PHONY: release
release: clean-logs
	puppet module build

.PHONY: test-intake
test-intake: test-docs test-rspec

.PHONY: test-acceptance
test-acceptance: bundle
	BEAKER_PE_DIR=spec/fixtures/artifacts \
		BEAKER_set=$(DISTRO) \
		bundle exec rake beaker:acceptance

.PHONY: test-integration
test-integration: bundle
	BEAKER_PE_DIR=spec/fixtures/artifacts \
		BEAKER_PE_VER=$(PE_VER) \
		BEAKER_IS_PE=$(PE) \
		BEAKER_set=$(DISTRO) \
		bundle exec rake beaker:integration

.PHONY: test-docs
test-docs: bundle
	bundle exec rake parse_doc

.PHONY: test-rspec
test-rspec: bundle
	bundle exec rake lint
	bundle exec rake validate
	STRICT_VARIABLES=$(STRICT_VARIABLES) \
		bundle exec rake spec_verbose
