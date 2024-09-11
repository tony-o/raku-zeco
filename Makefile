export FEZ_ECO_CONFIG := resources/test-fez-eco-config.toml
export FEZ_CONFIG     := resources/test-fez-config.json

dev:
	raku -I. -M Zeco 

integration:
	find xt -name '*.rakutest' | sort | xargs -I{} bash -c 'echo {} && raku -I../fez -I. {}'

test:
	raku -I. $(xt)
