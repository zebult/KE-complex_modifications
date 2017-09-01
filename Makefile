all:
	scripts/update-json.sh
	scripts/json2exhtml.rb < docs/json/personal_rcmdnk.json > src/extra_descriptions/personal_rcmdnk.json.html
	scripts/json2exhtml.rb < docs/json/vim_emu.json > src/extra_descriptions/vim_emu.json.html
	scripts/erb2html.rb < src/index.html.erb > docs/index.html
	scripts/apply-lint.sh

rebuild:
	touch src/json/*
	$(MAKE) all
