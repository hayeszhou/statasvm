Compiling Stata-SVM
===================

Toolchain
---------

To build, you will need to have your platform's toolchain installed, of course.

On Windows, you will need to [get gmake](http://gnuwin32.sourceforge.net/packages/make.htm), and you will also need a compiler (MinGW or Visual Studio) installed.
Unlike the POSIX compilers, if you want to use Visual Studio, you need to amend your %PATH% by [using `vcvarsall.bat`](https://msdn.microsoft.com/en-us/library/x4d2c09s.aspx); for 32 bit builds:
```
C:> "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"
```
and for 64-bit:
```
C:> "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64
```
Unlike VS, MinGW is by default installed on the %PATH% (TODO: confirm this), and the makefile checks for VS first,
so if you have both installed you can choose which to use simply by amending or not amending your %PATH%.

On OS X, you will need XCode or at least the minimal [Command Line Tools](TODO).

Similarly, on Linux, there will also be a package for this, but it's name changes depending on your distro; for example in Debian `apt-get install build-essentials`, and on Arch `pacman -S base-devel` will get you the tools.

On both OS X and Linux, you can test if you have the compiler installed with
```
$ gcc -v
```

Building
--------

Once you have set up a compiler, open a shell **in the `src/` subdirectory** and run
```
$ make
```

(If the build fails for you **please file bug reports**. We are a small team and cannot cover all platforms at all times, but we will address your problem and help you to help us improve the package.)

Testing
-------

You can run the unit tests with, 
```
$ make test
```
but you will need Stata installed and activated for this, of course.

Installation/Deployment
-----------------------

TODO