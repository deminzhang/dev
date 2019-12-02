--cs_recharge.lua
local keyidx={'sid','uid','oid','money','gold','time','platform'}

--��ֵ
function _G.Recharge(uid,order,channel,rmb,gold)--�ʺţ������ţ�����������ֵRMB����Ԫ��
	local p = _ORM'player':where{ uid=uid, delflag=false }:select()
	if not p then return -11 end	--�ʺŻ��ɫ������
	p = p[1]
	local a = _ORM:table'account':where{uid=uid}:select()[1]
	local createserver = a.server_id --�Ϸ�ǰԴ��id
	local orderid = createserver..'_'..order
	local oldlog = _ORM'recharge':where{ orderid=orderid }:select()
	if oldlog then return -12 end--�ظ�ʹ�õĶ�����
	local pid = p.pid
	local old = a.gold
	local oldacc = a.accgold
	local new = old + gold
	local newacc = oldacc + gold
	local newtimes = a.rechargetimes+1
	_ORM'account':where{uid=uid}:update{gold=new, accgold=newacc, rechargetimes=newtimes}
	--��־
	local d = _time({}, _now())
	local daykey = d.year*10000+d.month*100+d.day--�ռ�����ֵ�ղ�ѯ��
	local lg = DefaultDB.get'recharge'	--�ɶ�������־
	lg.orderid	= orderid
	lg.uid		= uid
	lg.daykey	= daykey
	lg.channel	= channel
	lg.rmb		= rmb
	lg.gold		= gold
	lg.fgold	= new
	lg.time		= _now(0)
	_ORM'recharge':insert(lg)
	Log.sys('>>RechargeOK:', uid, order, channel, rmb, gold, p.pid, p.name)
	onGetGold{pid=pid,num=gold,lab='recharge',old=old,new=new, acc=newacc, cost=a.costgold}
	if channel~='gm' then
		CYLog.log( 'recharge', { roleid=pid,uid=uid,amount=gold,money=toint(rmb),channel=channel,balance=new,level=p.level,order=order, accgold=newacc, acccost=a.costgold}, Client.byPID(pid) )
	end
	CallPlayer(pid).Gold{Num=new,Add=gold,Acc=newacc,Cost=a.costgold, T={rechargetimes=newtimes,dailyrecharge=Role.getDailyRecharge(pid)} }
	return 1
end

--event ------------------------------
when{} function loadConfigCS()
	DefaultDB.add( 'recharge', {
		orderid	= 0,		--������
		uid		= '',		--�ʺ�account.uid
		daykey	= 0,		--���ڼ�YYYYMMDD�����ճ�ֵͳ�Ʋ�ѯ
		channel	= '',		--����
		rmb		= 0,		--�ֽ�ֵ(��)
		gold	= 0,		--��ֵ��
		fgold	= 0,		--��ֵ��
		time	= 0,		--ʱ��
	} )
end


_G.rechargeip = {
	'121.43.115.122',
	'121.43.115.123',
	'10.1.33.242',
	'124.65.159.118',
	'119.29.205.241',
	'47.88.5.230',		--191game�ĳ�ֵ������
	'10.117.226.249',	--191game�ĳ�ֵ������
	'124.236.131.132',	--191game�ĳ�ֵ������
}

when{ Interface = 'pay', _order = 0 }function http( Params, _args )
	if _G.rechargeip then
		local invalid = true
		for i, v in ipairs( rechargeip ) do
			if v == _from.ipstr then invalid = false break end
		end
		if invalid then
			Log.sys( "rechargeinvalid", _from.ipstr, table.tostr( Params ) )
			_from:close'invalid_rechargeip'
			_args._stop = true
			return
		end
	end
end

if os.info.platform == 'tencent' then
	--[[
		openid	string	��APPͨ�ŵ��û�key����ת��Ӧ����ҳ��URL�����ò�������ƽֱ̨�Ӵ���Ӧ�ã�Ӧ��ԭ������ƽ̨���ɡ�
		����APPID�Լ�QQ�������ɣ�����ͬ��appid�£�ͬһ��QQ�����ɵ�OpenID�ǲ�һ���ġ�
		appid	string	Ӧ�õ�ΨһID������ͨ��appid����APP������Ϣ��
		ts	string	linuxʱ�����
		ע�⿪���ߵĻ���ʱ������Ѷ�Ʒѿ���ƽ̨��ʱ�����ܳ���15���ӡ�
		payitem	string	��Ʒ��Ϣ��
		��1�����ձ�׼��ʽΪID*price*num���ش�ʱIDΪ�ش�����������ײ���Ʒ���á�;���ָ����ַ����в��ܰ���"|"�����ַ���
		��2��ID��ʾ��ƷID��price��ʾ���ۣ���Q��Ϊ��λ���������ٲ�������2Q�㣬1Q��=10Q�㡣���۵��ƶ�����ѭ���߶��۹淶����num��ʾ���յĹ���������
		ʾ����
		���������ײͣ��ײ��а�����Ʒ1����Ʒ2����Ʒ1��IDΪG001������Ʒ�ĵ���Ϊ10Q�㣬��������Ϊ1����Ʒ2��IDΪG008������Ʒ�ĵ���Ϊ8Q�㣬��������Ϊ2����payitemΪ��G001*10*1;G008*8*2 ��
		token	string	Ӧ�õ���v3/pay/buy_goods�ӿڳɹ����صĽ���token��
		ע�⣬����token����Ч��Ϊ15���ӣ������ڻ�ȡ��token���15�����ڴ��ݸ�token�����򽫻᷵��token�����ڵĴ���
		billno	string	֧����ˮ�ţ�64���ַ����ȡ����ֶκ�openid��������Ψһ�ģ���
		version	string	Э��汾�ţ����ڻ���V3��OpenAPI������һ�����ء�v3����
		zoneid	string	��֧��Ӫ����������˵��ҳ�棬���õķ���ID��Ϊ����ġ�zoneid����
		���Ӧ�ò���������Ϊ0��
		�ص�������ʱ�򣬸���������д��zoneidʵ�ַ���������
		ע��2013������ļ���Ӧ�ã��˲�������Ϊ������������Ҫ�����������Ϊ���������Ϊ����ɵ�������ʧ���ɿ��������ге���
		providetype	string	�������ͣ������봫��0��
		0��ʾ���߹���1��ʾӪ����еĵ������ͣ�2��ʾ����Ӫ���������еĽ������š�
		amt	string	Q��/Q�����Ľ���Ƹ�ͨ��Ϸ���˻��Ŀۿ������Ϊ�գ������ݿ�ֵ�򲻴����������ʾδʹ��Q��/Q��/�Ƹ�ͨ��Ϸ���˻���
		������Ϸ�ҡ�Q�㡢�ֿ�ȯ���߻��֧������ֻ������ĳһ�ֽ���֧����������û��������ʱ��ϵͳ�����ȿ۳��û��˻��ϵ���Ϸ�ң���Ϸ������ʱ��ʹ��Q��֧����Q�㲻��ʱʹ��Q��/�Ƹ�ͨ��Ϸ���˻���
		�����amt��ֵ��������㣬����ֳɡ�
		ע�⣬������0.1Q��Ϊ��λ��������ܽ��Ϊ18Q�㣬��������ʾ��������180���뿪���߹�ע���ر��Ƕ��˵�ʱ��ע�ⵥλ��ת����
		payamt_coins	string	��ȡ����Ϸ����������λΪQ�㡣����Ϊ�գ������ݿ�ֵ�򲻴����������ʾδʹ����Ϸ�ҡ�
		������Ϸ�ҡ�Q�㡢�ֿ�ȯ���߻��֧������ֻ������ĳһ�ֽ���֧����������û��������ʱ��ϵͳ�����ȿ۳��û��˻��ϵ���Ϸ�ң���Ϸ������ʱ��ʹ��Q��֧����Q�㲻��ʱʹ��Q��/�Ƹ�ͨ��Ϸ���˻���
		��Ϸ����ƽ̨���ͻ��ɺ��Ѵ��ͣ�ƽ̨���͵���Ϸ�Ҳ�������㣬��������ֳɣ����Ѵ��͵���Ϸ�Ұ�������������㣨�����������ϵ��֧����������
		pubacct_payamt_coins	string	��ȡ�ĵ���ȯ�ܽ���λΪQ�㡣����Ϊ�գ������ݿ�ֵ�򲻴����������ʾδʹ�õֿ�ȯ��
		������Ϸ�ҡ�Q�㡢�ֿ�ȯ���߻��֧������ֻ������ĳһ�ֽ���֧����������û��������ʱ������ѡ��ʹ�õֿ�ȯ����һ���ֵĵֿۣ�ʣ�ಿ��ʹ����Ϸ��/Q�㡣
		ƽ̨Ĭ����������֧����Ӧ�þ�֧�ֵֿ�ȯ����2012��7��1���𣬽�ȯ��ȯ���Ľ���Q������һ������������㣨�����������ϵ��֧����������
		sig	string	���󴮵�ǩ��������Ҫǩ���Ĳ������ɡ�
		��1��ǩ����������ĵ�����Ѷ����ƽ̨������Ӧ��ǩ������sig��˵����
		��2�����������ĵ�����ǩ������ʱ����ע��ص�Э��������һ�����裺
		�ڹ���Դ���ĵ�3�����������Ĳ���(key=value)��&ƴ��������������URL���롱֮ǰ�����value�Ƚ���һ�α��� ���������Ϊ������ 0~9 a~z A~Z !*() ֮�������ַ�����ASCII���ʮ�����Ƽ�%���б�ʾ�����硰-������Ϊ��%2D������
		��3����ÿ�ʽ��׽��յ��Ĳ���Ϊ׼�����յ������в�����sig���ⶼҪ����ǩ����Ϊ����ƽ̨������Э�������չ���벻Ҫ������ǩ���Ĳ���д����
		��4�����в�������string�ͣ�����ǩ��ʱ����ʹ��ԭʼ���յ���string��ֵ�� �����̳��ڱ��ؼ��˵�Ŀ�ģ��Խ��յ���ĳЩ����ֵ��תΪ��ֵ����תΪstring�ͣ������ַ������ֱ��ضϣ��Ӷ�����ǩ���������Ҫ���б��ؼ��˵��߼�������������ı���������ת�������ֵ��
	]]
	when{ Interface = 'pay' } function http( Action, Params )
		Log.sys( "Recharge1", table.tostr( Params ) )
		local openid = Params.openid
		local zoneid = Params.zoneid
		local map = TecentMap[openid]
		local sid = zoneid == '0' and os.info.server_id or ( map and map[zoneid] )
		local uid0 = sid .. '|' .. openid
		local c = Client.byUID( uid0 )
		if not c then
			Net.sendJson( _from, { ret = 4, msg = '��ɫ������' } )
			return
		end
		local appid = Params.appid
		local ts = Params.ts
		local payitem = Params.payitem
		local token = Params.token
		local billno = Params.billno
		local version = Params.version
		local providetype = Params.providetype
		local amt = Params.amt
		local payamt_coins = Params.payamt_coins
		local pubacct_payamt_coins = Params.pubacct_payamt_coins
		local sig = Params.sig
		Params.sig = nil
		local sign, sourcestr = getPaySign( Action, "/pay", Params )
		Log.sys( "RechargeSign", sig, sign, sourcestr )
		if CHECKTENCENTSIGN and sig ~= sign then
			Net.sendJson( _from, { ret = 4, msg = 'param sig error' } )
			return
		end
		local oid = openid.."|"..billno
		local money = toint( tonumber(amt) )	--rmb��
		local ss = string.split( payitem, "%*" )
		local gold
		local itemid = ss[1]
		local num = ss[3] or 1
		for _, idx in next, cfg_pay do
			if idx.payitem:lead( itemid ) then
				gold = idx.pay * toint( num )	--��ֵ��
			end
		end
		local time = ts		--unixʱ����
		local platform = os.info.platform
		local sign = sig
		Log.sys( "Recharge2", uid0, oid, platform or '', money, gold )
		local r = Recharge( uid0, oid, platform or '', money, gold )
		Log.sys( "Recharge3", r )
		if r == 1 then
			Net.sendJson( _from, { ret = 0, msg = 'suc' } )
			--֪ͨ��Ѷ
			local info = c.getNet( )._logininfo
			--����ȷ�϶�������Ѷ�ᱨ��
			confirm_delivery{ cinfo = { openid, info, ts, payitem, token, billno, zoneid, amt, payamt_coins }, _delay = 1}
		else
			Net.sendJson( _from, { ret = 4, msg = tostring( r ) } )
		end
	end

	cdefine.ignore.confirm_delivery{ cinfo = { }}
	when{}
	function confirm_delivery( cinfo )
		local openid, info, ts, payitem, token, billno, zoneid, amt, payamt_coins =
		cinfo[1], cinfo[2], cinfo[3], cinfo[4], cinfo[5], cinfo[6], cinfo[7], cinfo[8], cinfo[9], cinfo[10]
		openapi_confirm_delivery( function( result )
			Log.sys( "rechargecomfire", openid, result )
		end, function( err )
			Log.sys( "rechargefail", openid, err )
		end, openid, info.openkey, info.rechargepf or info.pf, ts, payitem, token, billno, zoneid, 0, amt, payamt_coins )
	end
else
	when{ Interface = 'pay' } function http( Params )
		local response = function( s, s1 )
			Net.sendText( _from, tostring(s) )
			Log.sys( 'payrespond', s, s1 or 'noreason' )
		end
		Log.sys('pay', table.tostr( Params ), _from.ipstr )
		local sid = Params.sid				--��id
		local uid = Params.uid				--uid
		local oid = Params.oid				--������
		local money = toint(Params.money) 	--rmb��
		local gold = toint(Params.gold) 	--��ֵ��
		local time = toint(Params.time)		--unixʱ����
		local platform = Params.platform
		local sign = Params.sign

		if not sid then response( -19, 'nosid' ) return end
		if not uid then response( -19, 'nouid' ) return end
		if not oid then response( -19, 'nooid' ) return end
		if not money then response( -19, 'nomoney' ) return end
		if not gold then response( -19, 'nogold' ) return end
		sid = WrapPlatSid( sid )
		if not NOPAYAUTH then
			if not time then response( -19, 'notime' ) return end
			if not platform then response( -19, 'noplatform' ) return end
			if not sign then response( -19, 'nosign' ) return end

			local timeout = math.abs( unixNow0( ) - time * 1000000 ) > 300000000
			if timeout then return response( -14, 'timeout' ) end 	--TODO �������� �رշ�������벹��
			if money <= 0 then response( -15, 'invalidmoney' ) return end
			if gold <= 0 then response( -16, 'invalidgold' ) return end

			local kvs = {}
			for i,k in ipairs(keyidx) do
				kvs[#kvs+1] = k..'='..Params[k]
			end

			local fmt = table.concat(kvs,'&')..Cfg_Plat.RechargeKey

			Log.sys( fmt )
			local csign = fmt:md5()
			Log.sys( fmt, csign, sign,'all' )
			if sign ~= csign then response( -17 ) return end
		end

		local uid0 = sid .. '|' .. uid
		local r = Recharge( uid0, oid, platform or '', money, gold )
		response( r )
		return
	end
end