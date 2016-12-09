PREFIX=/usr
MANDIR=$(PREFIX)/share/man
BINDIR=$(PREFIX)/share/guestwlan

all:
	  @echo "Run 'make install' for installation."
	  @echo "Run 'make uninstall' for uninstallation."

install:
		install -Dm755 guestwlan.sh $(DESTDIR)$(BINDIR)/guestwlan.sh
		install -Dm755 guestwlan.py $(DESTDIR)$(BINDIR)/guestwlan.py
		install -Dm755 guestwlan.kv $(DESTDIR)$(BINDIR)/guestwlan.kv
		install -Dm755 wlanqrkeygen.sh $(DESTDIR)$(BINDIR)/wlanqrkeygen.sh

		mkdir -p $(DESTDIR)$(PREFIX)/bin
		ln -s $(BINDIR)/guestwlan.sh $(DESTDIR)$(PREFIX)/bin/guestwlan
		ln -s $(BINDIR)/wlanqrkeygen.sh $(DESTDIR)$(PREFIX)/bin/wlanqrkeygen

		install -Dm644 guestwlan.cfg $(DESTDIR)/etc/guestwlan.cfg
		install -Dm600 create_guest_ap.conf $(DESTDIR)/etc/create_guest_ap.conf

		[ ! -d /lib/systemd/system ] || install -Dm644 create_guest_ap.service $(DESTDIR)$(PREFIX)/lib/systemd/system/create_guest_ap.service
		[ ! -d /lib/systemd/system ] || install -Dm644 guestwlan.service $(DESTDIR)$(PREFIX)/lib/systemd/system/guestwlan.service
		[ ! -d /lib/systemd/system ] || install -Dm644 guestwlan.target $(DESTDIR)$(PREFIX)/lib/systemd/system/guestwlan.target
		[ ! -d /lib/systemd/system ] || install -Dm644 wlanqrkeygen.service $(DESTDIR)$(PREFIX)/lib/systemd/system/wlanqrkeygen.service
		[ ! -d /lib/systemd/system ] || install -Dm644 wlanqrkeygen.timer $(DESTDIR)$(PREFIX)/lib/systemd/system/wlanqrkeygen.timer

		install -Dm644 Readme.md $(DESTDIR)$(PREFIX)/share/doc/guestwlan/Readme.md

		mkdir -p $(DESTDIR)/var/lib/guestwlan/pictures

uninstall:
		rm -f $(DESTDIR)$(BINDIR)/guestwlan.sh
		rm -f $(DESTDIR)$(BINDIR)/guestwlan.py
		rm -f $(DESTDIR)$(BINDIR)/guestwlan.kv
		rm -f $(DESTDIR)$(BINDIR)/wlanqrkeygen.sh

		rm -f $(DESTDIR)$(PREFIX)/bin/guestwlan
		rm -f $(DESTDIR)$(PREFIX)/bin/wlanqrkeygen

		rm -f $(DESTDIR)/etc/guestwlan.conf
		rm -f $(DESTDIR)/etc/create_guest_ap.conf

		[ ! -f /lib/systemd/system/create_guest_ap.service ] || rm -f create_guest_ap.service $(DESTDIR)$(PREFIX)/lib/systemd/system/create_guest_ap.service
		[ ! -f /lib/systemd/system/guestwlan.service ] || rm -f guestwlan.service $(DESTDIR)$(PREFIX)/lib/systemd/system/guestwlan.service
		[ ! -f /lib/systemd/system/guestwlan.target ] || rm -f guestwlan.service $(DESTDIR)$(PREFIX)/lib/systemd/system/guestwlan.target
		[ ! -f /lib/systemd/system/wlanqrkeygen.service ] || rm -f wlanqrkeygen.service $(DESTDIR)$(PREFIX)/lib/systemd/system/wlanqrkeygen.service
		[ ! -f /lib/systemd/system/wlanqrkeygen.timer ] || rm -f wlanqrkeygen.timer $(DESTDIR)$(PREFIX)/lib/systemd/system/wlanqrkeygen.timer

		rm -f $(DESTDIR)$(PREFIX)/share/doc/guestwlan/Readme.md

		echo "Please remove files in /var/lib/guestwlan yourself."

tar:
		tar --exclude='*.tar.gz' -zcvf guestwlan.tar.gz *
