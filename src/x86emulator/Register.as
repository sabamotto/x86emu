package x86emulator
{
	import flash.errors.IOError;
	
	/**
	 * レジスタ制御クラス。
	 * @author SabaMotto
	 */
	internal class Register
	{
		
		public var EAX:uint, EBX:uint, ECX:uint, EDX:uint;
		public var EIP:uint;
		
		public function Register()
		{
			EAX = EBX = ECX = EDX = 0;
			EIP = 0;
		}
		
		/**
		 * 汎用レジスタをuintの配列にして返す。
		 * @param	reverse - 順序を逆にする（おまけ？）
		 * @return 汎用レジスタの値の配列
		 */
		public function eachGRegs(reverse:Boolean = false):Array
		{
			if (reverse)
				return [EDX, ECX, EBX, EAX];
			return [EAX, EBX, ECX, EDX];
		}
		
		/**
		 * 指定した4つのuintをもった配列を汎用レジスタに設定する。
		 * @param	gRegs - 設定する値の配列
		 * @param	reverse - 順序を逆にする（スタック用）
		 */
		public function setGRegs(gRegs:Array, reverse:Boolean = false):void
		{
			if (gRegs.length != 4)
				throw IOError;
			if (reverse)
				gRegs.reverse();
			EAX = gRegs[0];
			EBX = gRegs[1];
			ECX = gRegs[2];
			EDX = gRegs[3];
		}
		
		public function dump(out:Function):void
		{
			out("EAX:" + EAX.toString(16) + ", EBX:" + EBX.toString(16) + ", ECX:" + ECX.toString(16) + ", EDX:" + EDX.toString(16));
			out("EIP:"+EIP.toString(16))
		}
	
	}

}

