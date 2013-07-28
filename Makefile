
SHELL := /bin/bash

PAGES := index.html about.html documentation.html screenshots.html download.html
PAGES += $(addsuffix .html,$(basename $(wildcard cmd_*.in)))

web: $(PAGES)

index.html:
	ln -s about.html index.html

%.html: %.in templates/* files/*
	perl -pe ' #\
		if (/^@(\S+)\s*(.*)@\s*$$/) { #\
			open(F, "<templates/$$1.in") or die $$!; $$y=$$2; $$x=""; $$x.=$$_ while <F>; close F; #\
			$$_=$$x; s/\@\@/$$y/g; s/\@$(basename $@)\@/1/g; s/\@[0-9a-zA-Z_]*\@/0/g; } #\
		if (/^\[\[(.*)\]\]$$/) { $$fn = $$1; open(F, "files/$$fn") or die $$!; $$x=""; $$x.=$$_ while <F>; close F; #\
			s/([^a-zA-Z0-9 \t\n])/"&#".ord($1).";"/eg; $$_="<pre>$$x</pre>\n"; #\
			$$_ .= "<div class=\"file\"><a href=\"files/$$fn\">$$fn</a></div>\n"; } #\
		' $< > $@.new
	mv $@.new $@

update_cmd:
	rm -f cmd_*.html
	git rm --ignore-unmatch -f cmd_*.in templates/cmd_index.in
	yosys -qp 'help -write-web-command-reference-manual'
	git add cmd_*.in templates/cmd_index.in

update_show:
	git rm --ignore-unmatch -f images/show_*.png
	yosys-filterlib -verilogsim < files/cmos_cells.lib > files/cmos_cells.v
	cd files; for ys in show_*.ys; do \
		yosys $$ys -p "show -lib cmos_cells.v -lib coarse_cells.v -format png -prefix ../images/$${ys%.ys}"; \
		rm ../images/$${ys%.ys}.dot; \
	done
	rm -f files/cmos_cells.v
	git add images/show_*.png

push: web
	rsync -e ssh -av --delete --exclude .git . clifford@clifford.at:htdocs/clifford/yosys/.

clean:
	rm -f $(PAGES)

.PHONY: web push clean
