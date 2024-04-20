---
title: Rhea
date: 2024-01-23T11:01:12-05:00
draft: true
description: a hobby rust kernel
---

Rhea is my second attempt at building a kernel in rust. My knowledge of both the
x86-64 platform and the rust language have both increased greatly since my last
attempt at such a project, and I'm hopeful about the future of this project.

## Build System

Normally the build system for a rust project wouldn't deserve any special
attention, but in this case there are actually some interesting things
happening. The rhea project is a workspace with three crates:
1. the kernel itself
2. the UEFI bootloader
3. a root crate which handles building bootable disk images

I could easily have set up a shell script to handle building the images using
standard command line tools, but my goal was always to make it so that I could
simply type `cargo build` to build a disk image and `cargo run` to start the
system in a VM. To this end, the root crate uses a cargo build script to handle
programatiicaly creating the bootable image and passing its location to the
actual binary defined by the root crate, which is a small program that can tell
the user the location of the created disk image (for use in other scripts) or
start QEMU running the created image. Images for different architectures
(currently only x86-64 and aarch64) can be generated through the use of cargo
features. This system solves the issues created by cargo lacking a post-build
step that can be hooked into like build scripts allow for the pre-build step and
deals with the weirdness created by the fact that the loader and kernel have to
be cross compiled for 2 different targets (since UEFI uses a different[^1] ABI
from the ELF format all my tools are meant to deal with). The end result is
a very smooth developer experience with a build system set up entirely in the
language of the project 🙂

[^1]: read: worse

## Booting

I decided to go with my own bootloader instead of just using grub primarily for
educational purposes.[^2] All my loader has to be capable of doing is
decompressing the kernel, loading it into memory, setting up paging, and passing
a memory map to the kernel when it hands over control, none of which are very
complicated tasks with the luxuries of UEFI. In the future to increase
compatibility with other hardware (which might not support UEFI) I might
implement support for other bootloaders.

[^2]: also because it makes the process of generating my bootable images simpler

Locating the kernel and determining whether or not the kernel image is
compressed are done through a config file that is guaranteed to be located at
`/rhea.json` on the disk. In practice, the kernel will always be at `/kernel.elf`
or `/kernel.elf.gz` since that's where it's placed by the disk image creator,
but this system provides a certain amount of futureproofing and means that if
one wanted to create a disk with a more complicated structure, it would be
totally fine. This config file is generated using serde by the build script, and
is then read by the loader using serde's `no_std` support.

As far as paging goes, the job of the bootloader is to set things up such that
the kernel is able to later modify page tables as it needs to. This can be
achieved through recursive page tables (which are elegant and conceptually
appealing) or through simply mapping all of physical memory into kernel virtual
memory at a known address offset. Given the absolutely massive size of virtual
memory available on x86-64, this latter solution is appealing for the
simplicity of working with it. I've implemented both in the past, but for this
project I ended up settling on the offset mapping solution.

## Kernel Memory Management

Once the boot loader has passed control to the kernel, the first priority is
getting memory management set up so that we can have access to all the fun
language features that require heap allocation.

## Future Work

Thus far what I've achieved is only a foundation for an actual operating system
kernel. The next step is to implement IO of some kind (to a serial port or the
VGA text buffer) and then a basic file system driver, program loader and set of
syscalls to allow running programs other than the kernel. Another feature that's
high on my list of priorities is dynamically loadable and unloadable modules and
SMP support.
