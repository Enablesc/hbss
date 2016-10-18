#!/usr/bin/make -f

DESTDIR =

all : install

install :
	install -D -m0744 backup.sh $(DESTDIR)/usr/local/bin/backup.sh
	install -D -m0744 cronbackup.sh $(DESTDIR)/usr/local/bin/cronbackup.sh
	install -D -m0644 backup.cfg $(DESTDIR)/etc/backup.cfg
	install -D -m0644 cronbackup.cfg $(DESTDIR)/etc/cronbackup.cfg
