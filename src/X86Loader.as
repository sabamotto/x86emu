package
{
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	import mx.core.*;
	import x86emulator.*;
	
	public class X86Loader
	{
		
		private var changeMode:Function;
		private var print:Function;
		private var data:ByteArray = null;
		private var x86:X86Emulator = null;
		
		public function X86Loader(chgFunc:Function, outFunc:Function)
		{
			changeMode = chgFunc;
			print = outFunc;
		}
		
		public function load(file:String):void
		{
			var self:X86Loader = this;
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			try
			{
				loader.load(new URLRequest(file));
			}
			catch (error:SecurityError)
			{
				self.print("[ERROR] a security error has occurred.");
			}
			
			loader.addEventListener(Event.COMPLETE, function(e:Event):void
				{
					data = ByteArray(loader.data);
					changeMode(X86LoaderMode.NO_INITIALIZED);
				});
			
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void
				{
					self.print("[ERROR] io error has occurred.");
				});
			
			self.print("[SYSTEM] Loading target data for uri.");
		}
		
		public function loadLocal():void
		{
			var self:X86Loader = this;
			var fr:FileReference = new FileReference();
			fr.addEventListener(Event.SELECT, function(e:Event):void
				{
					fr.addEventListener(ProgressEvent.PROGRESS, function(e:ProgressEvent):void
						{
							self.print("[SYSTEM] Loading now... [" + e.bytesLoaded + "/" + e.bytesTotal + "]");
						});
					fr.addEventListener(Event.COMPLETE, function(e:Event):void
						{
							data = fr.data;
							changeMode(X86LoaderMode.NO_INITIALIZED);
						});
					fr.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void
						{
							self.print("[ERROR] io error has occurred.");
						});
					fr.load();
				});
			this.print("[SYSTEM] Please select a binary code.")
			fr.browse();
		}
		
		public function init():void
		{
			if (data == null)
				return;
			x86 = new X86Emulator(data);
			this.print("[SYSTEM] Initialized X86 Emulator.");
			changeMode(X86LoaderMode.EXECUTING);
		}
		
		public function unload():void
		{
			data = null;
			x86 = null;
			changeMode(X86LoaderMode.NO_LOADED);
		}
		
		public function stepExecute(debug:Boolean = false):void
		{
			if (!x86)
				return;
			var res:uint = x86.execute((debug) ? this.print : null);
			if (res == 1)
			{
				this.print("[SYSTEM] Returned an end-code by x86-emulator.");
				changeMode(X86LoaderMode.END_MEMORY);
			}
			else if (res)
			{
				this.print("[SYSTEM] Returned [" + res.toString(16) + "] by x86-emulator.");
			}
		}
		
		public function dump():void
		{
			if (!x86)
				return;
			x86.dump(this.print);
		}
	
	}
}


