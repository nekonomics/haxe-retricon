package;


import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFieldAutoSize;
import openfl.display.SimpleButton;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import retricon.Retricon;
import retricon.Options;

class Main extends Sprite {

	private var _retricons:Array<Sprite>;
	private var _input:TextField;
	private var _original:Bitmap;
	
	public function new () {
		super ();
		this.addEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
	}

	private function _onAddedToStage(e:Event):Void {
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;

		_retricons = new Array<Sprite>();

		var opts:Options = new Options();

		_retricons.push(_generate("default", opts));

		opts.tiles = 3;
		opts.bgColor = 1;
		_retricons.push(_generate("mini", opts));

		opts.tiles = 8;
		opts.bgColor = 1;
		_retricons.push(_generate("gravatar", opts));

		opts.tiles = 6;
		opts.bgColor = "cccccc";
		opts.pixelColor = "000000";
		opts.pixelSize = 12;
		opts.pixelPadding = -1;
		opts.imagePadding = 5;
		_retricons.push(_generate("mono", opts));

		opts.tiles = 5;
		opts.bgColor = "f0f0f0";
		opts.pixelColor = 0;
		opts.pixelSize = 16;
		opts.pixelPadding = 1;
		opts.imagePadding = 1;
		_retricons.push(_generate("mosaic", opts));

		opts.tiles = 5;
		opts.bgColor = 0;
		opts.pixelColor = null;
		opts.pixelSize = 16;
		opts.pixelPadding = 1;
		opts.imagePadding = 1;
		_retricons.push(_generate("window", opts));

		opts.tiles = 8;
		opts.bgColor = 1;
		opts.pixelColor = 0;
		opts.pixelSize = 12;
		opts.pixelPadding = -2;
		_retricons.push(_generate("custom", opts));

		for(spr in _retricons) {
			this.addChild(spr);
		}

		opts = new Options();
		var str:String = "hello";
		_original = new Bitmap();
		_original.bitmapData = Retricon.retricon(str, opts);
		this.addChild(_original);

		_input = new TextField();
		_input.type = TextFieldType.INPUT;
		_input.border = true;
		_input.background = true;
		_input.backgroundColor = 0xffffff;
		_input.text = str;
		_input.autoSize = TextFieldAutoSize.LEFT;
		_input.width = 100;
		_input.multiline = false;
		_input.wordWrap = true;
		_input.height = _input.height;
		_input.autoSize = TextFieldAutoSize.NONE;
		_input.addEventListener(KeyboardEvent.KEY_UP, _onKeyUp);
		this.addChild(_input);

		_layout();

		stage.addEventListener(Event.RESIZE, _onStageResize);
	}

	private function _onStageResize(e:Event):Void {
		_layout();
	}

	private function _layout():Void {
		var num:Int = _retricons.length;
		var w:Int = Std.int(stage.stageWidth / num);
		var hw:Int = Std.int(w / 2);
		var y:Int = Std.int(stage.stageHeight / 2 - 150);
		for(i in 0..._retricons.length) {
			var spr:Sprite = _retricons[i];
			spr.x = i * w + hw;
			spr.y = y;
		}
		_original.x = (stage.stageWidth - _original.width) / 2;
		_original.y = Std.int(stage.stageHeight / 2 + 50);
		_input.x = (stage.stageWidth - _input.width) / 2;
		_input.y = _original.y + 80;
	}

	private function _generate(str:String, opts:Options):Sprite {
		var spr:Sprite = new Sprite();

		var bd:BitmapData = Retricon.retricon(str, opts);
		var bmp:Bitmap = new Bitmap(bd);
		bmp.x = -bmp.width / 2;
		bmp.y = -bmp.height / 2;
		spr.addChild(bmp);

		// var fmt:openfl.text.TextFormat = new openfl.text.TextFormat("_gothic", 10);

		var tf:TextField = new TextField();
		// tf.defaultTextFormat = fmt;
		tf.text = str;
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.x = -tf.width / 2;
		tf.y = 80;
		tf.textColor = 0x000000;
		spr.addChild(tf);

		return spr;
	}

	private function _onKeyUp(e:KeyboardEvent):Void {
		if(e.keyCode == 13) { // ENTER
			var opts:Options = new Options();
			_original.bitmapData = Retricon.retricon(_input.text, opts);
		}
	}
}