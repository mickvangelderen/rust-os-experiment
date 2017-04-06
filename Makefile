arch ?= x86_64

# source paths
arch_src_dir := src/arch/$(arch)
linker_script := $(arch_src_dir)/linker.ld
grub_cfg := $(arch_src_dir)/grub.cfg
assembly_source_files := $(wildcard $(arch_src_dir)/*.asm)

# build paths
arch_build_dir := build/arch/$(arch)
kernel := $(arch_build_dir)/kernel.bin
iso := $(arch_build_dir)/os.iso
assembly_object_files := $(patsubst $(arch_src_dir)/%.asm, $(arch_build_dir)/%.o, $(assembly_source_files))

.PHONY: all
all: $(kernel)

.PHONY: clean
clean:
	rm -r build

.PHONY: run
run: $(iso)
	qemu-system-x86_64 -cdrom $(iso)

.PHONY: iso
iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	mkdir -p build/isofiles/boot/grub
	cp $(kernel) build/isofiles/boot/kernel.bin
	cp $(grub_cfg) build/isofiles/boot/grub
	grub-mkrescue --output $(iso) build/isofiles
	rm -r build/isofiles

$(kernel): $(assembly_object_files) $(linker_script)
	ld --nmagic --script $(linker_script) --output $(kernel) $(assembly_object_files)

$(arch_build_dir)/%.o: $(arch_src_dir)/%.asm
	mkdir -p $(shell dirname $@)
	nasm -f elf64 $< -o $@
