export FEZ_ECO_CONFIG := resources/test-fez-eco-config.toml
export FEZ_CONFIG     := resources/test-fez-config.json

dev:
	raku -I. -e 'use Zeco; await start-server;' 

integration:
	cat META6.json  | grep '::' | grep '":' | awk -F': ' '{print$$1}' |  xargs -I{} bash -c 'if [[ $$(grep "use {}" lib -RnI | wc -l) -eq 0 ]]; then echo "{} unused"; exit 1;  fi'
	find xt -name '*.rakutest' | sort | xargs -I{} bash -c 'echo {} && raku -I../fez -I. {}'

test:
	raku -I. $(xt)

doc:
	find lib -name '*.rakumod' | xargs -I{} bash -c 'if [[ $$(grep "=begin pod" {} -nI | wc -l) -eq 0 ]]; then echo "{} missing =begin pod"; exit 1; fi; docpath=$$(echo -n "{}" | perl -p -e "s/lib/docs/g; s/rakumod$$/md/g"); echo "{}:: docpath: $$docpath"; mkdir -p $$(dirname $$docpath); raku -I. --doc=Markdown "{}" > "$$docpath"'
