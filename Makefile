build:
	cl65 -g -Ln gameol.lbl -m gameol.map -o gameol.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg gameol.s

run: build
	x64sc gameol.prg

debug: build
	x64sc -monitorfont 'Menlo 12' -moncommands gameol.lbl -moncommands breakpoints gameol.prg