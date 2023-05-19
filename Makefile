EXE=test
STEM=iolib calc

$(EXE) : $(addsuffix .o, $(STEM))
	ld -o $@ $^
	chmod u+x $@

%.o : %.asm
	nasm -felf64 $< -o $@


