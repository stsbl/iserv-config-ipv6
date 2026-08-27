LOCALE_DISABLE_POOTLE_DOWNLOAD=1

TEST_TARGETS += ipv6_tests

.PHONY: ipv6_tests
ipv6_tests:
	prove -lr tests
