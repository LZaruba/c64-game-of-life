build:
	cl65 -g -Ln gameol.lbl -m gameol.map -o gameol.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg gameol.s

run: build
	x64sc gameol.prg

debug: build
	x64sc -monitorfont 'Menlo 12' -moncommands gameol.lbl -moncommands breakpoints gameol.prg


# Testbed targets for trying out things outside of the main code
testbed_build:
	cl65 -g -Ln testbed.lbl -m testbed.map -o testbed.prg -u __EXEHDR__ -t c64 -C c64-asm.cfg testbed.s

testbed_run: testbed_build
	x64sc testbed.prg

testbed_debug: testbed_build
	x64sc -monitorfont 'Menlo 12' -moncommands testbed.lbl -moncommands breakpoints_testbed testbed.prg