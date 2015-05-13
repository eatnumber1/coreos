M4 ?= m4
CURL ?= curl

CLOUD_SIZE := 3

.PHONY: all clean realclean

all: cloud-config.yaml

clean:
	$(RM) cloud-config.yaml

realclean: clean
	$(RM) discovery.inc

cloud-config.yaml: cloud-config.m4 m4/license.inc m4/passwords.inc discovery.inc

discovery.inc:
	$(CURL) -o $@ 'https://discovery.etcd.io/new?size=$(CLOUD_SIZE)'

%.yaml: %.m4
	$(M4) $< > $@
