build:
	cl65 -o gameol.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg gameol.s

run: build
	x64sc gameol.prg