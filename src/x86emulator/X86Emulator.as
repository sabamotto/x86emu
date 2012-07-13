package x86emulator
{
	import flash.errors.*;
	import flash.utils.*;
	
	/**
	 * 簡易X86CPUエミュレータ。
	 * ただし、かなり謎仕様。
	 * @author SabaMotto
	 */
	public class X86Emulator
	{
		
		private var reg:Register; // レジスタ
		private var bytes:ByteArray; // バイトコード
		private var size:int = 0; // バイトコードのサイズ
		
		/**
		 * バイトコードの再書き込み（メモリ空間の再初期化）。
		 * 0...0xFFまでのデータがメモリに展開される。
		 * @param	bytes - 書きこむ元のバイトコード
		 */
		public function X86Emulator(bytes:ByteArray)
		{
			this.reg = new Register();
			this.rewrite(bytes);
		}
		
		/**
		 * 仮想マシンを再起動する（メモリは継続）。
		 * @param	startEIP - 実行開始アドレス（通常指定しない）
		 */
		public function reboot(startEIP:int = 0):void
		{
			reg = new Register();
			reg.EIP = startEIP;
			if (reg.EIP > this.size)
			{
				reg.EIP = 0;
				throw IOError;
			}
		}
		
		/**
		 * バイトコードを再書き込み（メモリ空間の再初期化）。
		 * 0...0xFFまでのデータがメモリに展開される。
		 * @param	bytes - 書きこむ元のバイトコード
		 */
		public function rewrite(bytes:ByteArray):void
		{
			this.size = bytes.length;
			if (this.size > 0x100)
				this.size = 0x100;
			this.bytes = new ByteArray();
			bytes.readBytes(this.bytes, 0, this.size);
			bytes.position = 0;
		}
		
		/**
		 * 一回分のオペコードを実行する（かなり適当）。
		 * @param	debug - 必要であればデバッグ出力先
		 * @return 正常実行時は0、終了時は1、エラーはその他が返される
		 */
		public function execute(debug:Function = null):uint
		{
			if (reg.EIP >= this.size)
				return 0x01;
			
			var result:uint = 0;
			var code:uint = getByte();
			var oprand:int = 0;
			var offset:int = 0;
			
			// 以下ALU部はパッケージに分離予定…？
			switch (code)
			{
				case 0x04: // ADD AL, X
					oprand = getByte();
					reg.EAX = (reg.EAX & 0xFFFFFF00) | (((reg.EAX & 0xFF) + (oprand)) & 0xFF);
					break;
				case 0xB0: // MOV AL, X
					oprand = getByte();
					reg.EAX = (reg.EAX & 0xFFFFFF00) | oprand;
					break;
				case 0xC3: // RET
					result = 0x01;	// とりあえずスタック実装がないのでCASL風に
					break;
				case 0xCD: // INT X
					oprand = getByte();
					// スタックないので仮のPC/AT互換機風実装
					// ただしI/O制御は未実装なので超適当
					if (oprand == 0x80 && reg.EAX == 1)	// これはLinux的な感じに…（ぉ
						result = 0x01;	// システムコール<sys.exit>
					else
						result = 0xF0;	// 仮番号
				case 0xE9: // JMP [(word)X]
					oprand = getWord();
					reg.EIP += oprand;
					break;
				case 0xF4:	// HLT
					result = 0x01;	// interrupt未実装なので…応急処置
					break;
				default: // 未実装 or 存在しない
					result = 0xFF;	// 仮番号
					break;
			}
			
			if (debug != null)
				debugMemory(code, oprand, offset, function(str:String):void
					{
						debug("[DBG] Code=0x" + code.toString(16) + "\t: " + str);
					});
			
			bytes.position = reg.EIP;	// JMP命令用
			
			return result;
		}
		
		/**
		 * レジスタと現在のアドレスのコードをダンプする。
		 * @param	out - 出力関数(str:String)
		 */
		public function dump(out:Function):void
		{
			reg.dump(function(str:String):void
				{
					out("[DUMP] " + str);
				});
			if (reg.EIP >= this.size)
			{
				out("[DUMP] Addr=0x" + reg.EIP.toString(16) + "\t: EOF");
				return;
			}
			
			var now:uint = reg.EIP;
			var code:uint = getByte(), oprand:int = 0, offset:int = 0;
			if (reg.EIP < this.size)
			{
				if (code != 0xE9)
					oprand = getByte();
				else
					oprand = getWord();	// 終端(EOF)確認をしていないのでエラーの可能性あり
			}
			if (reg.EIP < this.size)
				offset = getByte();
			debugMemory(code, oprand, offset, function(str:String):void
				{
					out("[DUMP] Addr=0x" + now.toString(16) + "\t: " + str);
				});
			bytes.position = now;
			reg.EIP = bytes.position;
		}
		
		private function debugMemory(code:uint, oprand:int, offset:int, out:Function):uint
		{
			// 非常に不便なのでALUパッケージで統一予定
			switch (code)
			{
				case 0x04: // ADD AL, X
					out("ADD AL, 0x" + oprand.toString(16));
					return 2;
				case 0xB0: // MOV AL, X
					out("MOV AL, 0x" + oprand.toString(16));
					return 2;
				case 0xC3: // RET(ERUN)
					out("RET");
					break;
				case 0xCD: // INT(ERRUPT) X
					out("INT 0x" + (oprand.toString(16)));
					break;
				case 0xE9: // JMP [(word)X]
					out("JMP 0x" + (bytes.position + oprand).toString(16));
					return 3;
				case 0xF4:
					out("HLT");
					break;
				default:
					out("DB 0x" + code.toString(16));
					break;
			}
			return 1;
		}
		
		/*-- 以下: 汎用メモリ読み込み制御 --*/
		
		private function getByte():uint
		{
			reg.EIP = bytes.position + 1;
			return bytes.readUnsignedByte();
		}
		
		private function getWord():int
		{
			var wordL:int = bytes.readUnsignedByte();
			var word:int = (bytes.readByte() << 8) | wordL;
			reg.EIP = bytes.position;
			return word;
		}
		
		private function getDWord():int
		{
			var word1:int = bytes.readUnsignedByte(),
				word2:int = bytes.readUnsignedByte()<<8,
				word3:int = bytes.readUnsignedByte()<<16;
			var word:int = (bytes.readByte() << 24) | word3 | word2 | word1;
			reg.EIP = bytes.position;
			return word;
		}
	
	}

}


