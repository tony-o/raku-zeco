dev:
	raku -I. -M Zeco 

export FEZ_ECO_CONFIG := resources/test-fez-eco-config.toml
export FEZ_CONFIG     := resources/test-fez-config.json

integration:
	find xt -name '09*.rakutest' | sort | xargs -I{} bash -c 'echo {} && raku -I../fez/ -I. {}'

test:
	raku -I. $(xt)
