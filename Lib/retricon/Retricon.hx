
package retricon;

import openfl.display.BitmapData;
import openfl.utils.Object;
import openfl.geom.Rectangle;
import haxe.crypto.Sha1;
import haxe.ds.Vector;
import haxe.ds.StringMap;

import retricon.Options;

class Retricon {

	public static function retricon(str:String, opts:Options):BitmapData {
		var dimension:Int = opts.tiles;
		var pixelSize:Int = opts.pixelSize;
		var border:Int = opts.pixelPadding;

		var mid:Int = Std.int(Math.ceil(dimension / 2));
		var n:Int = mid * dimension;

		var id:Result = _idhash(str, mid * dimension, opts.minFill, opts.maxFill);
		var pic:Array<Bool> = _refrect(id, dimension);
		var csize = (pixelSize * dimension) + (opts.imagePadding * 2);
		var bd:BitmapData = new BitmapData(csize, csize, true);

		var bgColor:UInt = 0;
		if(Std.is(opts.bgColor, Int)) {
			bgColor = (0xff << 24) | id.colors[opts.bgColor];
		} else if(Std.is(opts.bgColor, String)) {
			var prefix:String = "0x";
			if(opts.bgColor.length == 6) { prefix += "ff"; }
			bgColor = Std.parseInt(prefix + opts.bgColor);
		}

		var pixelColor:UInt = 0;
		if(Std.is(opts.pixelColor, Int)) {
			pixelColor = (0xff << 24) | id.colors[opts.pixelColor];
		} else if(Std.is(opts.pixelColor, String)) {
			var prefix:String = "0x";
			if(opts.pixelColor.length == 6) { prefix += "ff"; }
			pixelColor = Std.parseInt(prefix + opts.pixelColor);
		}

		if(opts.bgColor == null) {
			bd.fillRect(bd.rect, 0);
		} else {
			bd.fillRect(bd.rect, bgColor);
		}

		// draw
		var rect:Rectangle = new Rectangle();
		rect.width = rect.height = pixelSize - (border * 2);
		for(x in 0...dimension) {
			rect.x = (x * pixelSize) + border + opts.imagePadding;
			for(y in 0...dimension) {
				var i:Int = y * dimension + x;
				if(pic[i]) {
					rect.y = (y * pixelSize) + border + opts.imagePadding;
					bd.fillRect(rect, pixelColor);
				}
			}
		}

		return bd;
	}

		private static function _idhash(str:String, n:Int, minFill:Float, maxFill:Float):Result {
		for(i in 0...0x100) {
			var buf:String = str + StringTools.hex(i, 2);
			var f:Array<Int> = _fprintf(buf, Math.ceil(n/8)+6);
			var sliced:Array<Int> = f.slice(6);
			var pixels:Array<Bool> = new Array<Bool>();
			var setPixels:Int = 0;
			for(i in 0...sliced.length) {
				pixels = pixels.concat(_unpack(sliced[i]));
				if(pixels.length < n) {
					continue;
				}
				pixels.splice(n, pixels.length);
				for(j in 0...n) {
					if(pixels[j]) { setPixels ++; }
				}
				break;
			}

			var c:Array<Array<Int>> = new Array<Array<Int>>();
			c.push(f.slice(0, 3));
			c.push(f.slice(3, 6));
			c.sort(function(a, b) { return Std.int(-_cmpBrightness(a, b) * 100); });

			if(setPixels > (minFill * n) && setPixels < (maxFill * n)) {
				return new Result(
					c.map(function(x) { return _toColor(x); }),
					pixels
					);
			}
		}
		throw 'String $str unhashable in single-byte search space.';
	}

	private static function _refrect(id:Result, dimension:Int):Array<Bool> {
		var mid:Int = Math.ceil(dimension / 2);
		var odd:Bool = (dimension % 2) != 0;

		var pic:Array<Bool> = new Array<Bool>();
		for(row in 0...dimension) {
			for(col in 0...dimension) {
				var p = (row * mid) + col;
				if(col >= mid) {
					var d:Int = mid - (odd ? 1 : 0) - col;
					var ad:Int = Std.int(Math.abs(d));
					p = (row * mid) + mid - 1 - ad;
				}
				pic.push(id.pixels[p]);
			}
		}
		return pic;
	}

	// Inspired by:
	// https://code.google.com/p/nodejs-win/source/browse/node_modules/mysql/lib/auth.js
	private static function _xor(a:Array<Int>, b:Array<Int>):Array<Int> {
		var out:Array<Int> = new Array<Int>();
		var n:Int = Std.int(Math.min(a.length, b.length));
		var m:Int = Std.int(Math.max(a.length, b.length));
		var longer:Array<Int> = a.length > b.length ? a : b;
		for(i in 0...n) {
			out[i] = (a[i] ^ b[i]);
		}
		for(i in n...m) {
			out[i] = longer[i];
		}
		return out;
	}

	private static function _fprintf(buf:String, len:Int):Array<Int> {
		if(len > 20) {
			throw 'sha1 can only generate 20B of data: ${len}B requestd';
		}

		var encoded:String = Sha1.encode(buf);
		var digest:Array<Int> = new Array<Int>();
		for(i in 0...encoded.length) {
			if(i % 2 == 0) {
				digest.push(Std.parseInt("0x" + encoded.substr(i, 2)));
			}
		}

		// groupBy
		var grouped:StringMap<Array<Int>> = new StringMap<Array<Int>>();
		for(i in 0...digest.length) {
			var key:String = "" + Math.floor(i / len);
			if(!grouped.exists(key)) {
				grouped.set(key, new Array<Int>());
			}
			var list:Array<Int> = grouped.get(key);
			list.push(digest[i]);
		}

		// reduce(xor)
		var reduced:Array<Int> = null;
		for(a in grouped) {
			if(reduced != null) {
				reduced = _xor(reduced, a);
			}
			reduced = a;
		}

		return reduced;
	}

	private static function _unpack(nMask:Int):Array<Bool> {
		var a:Array<Bool> = new Array<Bool>();
		var nShifted:Int = nMask;
		for(i in 0...8) {
			a.push((nShifted & 0x01) != 0);
			nShifted >>>= 1;
		}
		return a;
	}

	private static function _brightness(r:Float, g:Float, b:Float):Float {
		// http://www.nbdtech.com/Blog/archive/2008/04/27/Calculating-the-Perceived-Brightness-of-a-Color.aspx
		return Math.sqrt(0.241 * r * r + 0.691 * g * g + 0.68 * b * b);
	}

	private static function _cmpBrightness(a:Array<Int>, b:Array<Int>):Float {
		return _brightness(a[0], a[1], a[2]) - _brightness(b[0], b[1], b[2]);
	}

	private static function _rcmpBrightness(a:Array<Int>, b:Array<Int>):Float {
		return _cmpBrightness(b, a);
	}

	private static function _toHexString(a:Array<Int>):String {
		return StringTools.hex(a[0], 2) + StringTools.hex(a[1], 2) + StringTools.hex(a[2], 2);
	}

	private static function _toColor(a:Array<Int>):UInt {
		return (a[0] << 16) | (a[1] << 8) | a[0];
	}

}

class Result {
	public var colors:Array<UInt>;
	public var pixels:Array<Bool>;
	public function new(colors:Array<UInt>, pixels:Array<Bool>):Void {
		this.colors = colors;
		this.pixels = pixels;
	}
	public function toString():String {
		return "[Result colors=" + colors + " pixels=" + pixels + "]";
	}
}