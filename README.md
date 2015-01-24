# haxe-retricon
Haxe/OpenFL port of node-retricon (https://github.com/sehrgut/node-retricon).

![alt text](https://github.com/nekonomics/haxe-retricon/blob/master/Doc/retricon.png)

## Install

Copy **retoricon** directory into your project directory.

## Usage

``` haxe
import retricon.Retricon;
import retricon.Options;
```

``` haxe
var opts:Options = new Options();
var bd:BitmapData = Retricon.retricon("hello", opts);
```

## Differences from original

* 8x8 tile images are the maximum.
  * Haxe/OpenFL has no built-in method to calculate SHA-512 hash.
