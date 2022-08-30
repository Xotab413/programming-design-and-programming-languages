# ASSEMBLER
## OVERVIEW
Hello little assembler's enjoyer, if you read this article, you ~~want~~ pass this subject 

First you should choose your way(asm) (NASM,MASM,YASM and e.t.c),you'll work with real mode

### NASM  
- good tutorial on [ravesli][ravesli] 
- short [lectures][githib_lectures] on github 
- Alexey Stolyarov [book][Stolyarov_book] <b>(BIG</b> recommendation read all volumes) 
- And Podenok's [lecture][Podenok_lectures] (mb for someone it'll be better choice)

I recommend this asm, because it's easy to install/use/learn, and of course big community

<b>Other asm, can be googled, if there is needs</b>

### TASM

This asm, i choose, because .... IDK why, mb lectures influenced on me or other stuff, doesn't matter

Books to understand/learn it: 
- [Tom SWAN][Swan], <b>READ</b> it first, you'll understand how to use TURBO debagger and other good stuff
- [Zubkov][Zubkov], this book will recommend lecturer, and as for me it's useful but only topics (Because TOM SWAN FIRSTLYYY)
- [Kalashnikov][Kalashnikov], you'll learn how to make resident virus on ASM, (of course with walkthroughs)

You can hate Tom SWAN book, and learn TASM in other books/sources, just LEARN it



## INSTALLTION 

### NASM

Go to nasm [site][nasm_site] and download last relise, or through terminal

### TASM

1) You can download virtual machine and install on it DOS, but i don't recommend, but it'll be useful in next semester on PCA (АПК). You can use 3 image of DOS and install it as Google said, or use ready-to-go VHD [image][virtual_machine] and zip-archive with TASM or BORLAND_C(which inlclude our TASM.exe file), you need to extract it to virtual machine, and here it is.

2) Use [DOSBOX][dosbox], but you also need tasm (links in previous method), install it bla bla bla, and it conf file in [autoexec] part write this lines (it helps you not to write them every time, when dosbox wakes):
```
mount C your_path_to_borlandC_orTASM/BORLANDC
path %PATH%;C:\BIN  # Bin in BORLAND_C variant, in tasm just C
mount f ~/path_to_your_labs
f:
```
3) When you install DOSbox, you can load [extension][extension] in VScode, which can run DOSbox in it, as for me it's necessary only for code-highlighting, and maybe for debuging (if you don't know what is TDB)


## THE END ?

First watch Alek OS [video][youtube], it'll help you understand first lab (Hello world)

If u like pain and, mb not a newbie in this theme read [Art of Intel x86][Art_of_assembly_language]

### ASS we CAN
### If I passed it, you will also pass !!! :3





<!---NASM's links-->
[ravesli]: https://ravesli.com/uroki-assemblera
[githib_lectures]: https://0xax.github.io/categories/assembler/
[Stolyarov_book]: http://www.stolyarov.info/books/pdf/progintro_vol2.pdf
[Podenok_lectures]: https://disk.yandex.by/d/uS0s4zZStus3TA
[nasm_site]: https://www.nasm.us

<!--- TASM's links-->
[Zubkov]:https://disk.yandex.by/i/OgZUXl7B6mj2hA
[Swan]: https://disk.yandex.by/i/xpeoXuSMzZFlOg
[Kalashnikov]: https://disk.yandex.by/i/x8En2MnxEce8gA
[virtual_machine]: https://disk.yandex.by/d/ZQ66ppYRUyykXQ
[dosbox]: https://www.dosbox.com/wiki/Basic_Setup_and_Installation_of_DosBox
[extension]: https://github.com/dosasm/masm-tasm/blob/HEAD/README.md


<!--- BASE links-->
[youtube]: https://youtu.be/PHyIP9g9BQw
[Art_of_assembly_language]: https://www.ic.unicamp.br/~pannain/mc404/aulas/pdfs/Art%20Of%20Intel%20x86%20Assembly.pdf