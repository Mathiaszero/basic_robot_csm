-- BIGNUM by rnd v05122018b
-- functions: 
--	new, tostring, rnd, import/exportdec,import/exporthex _add, _sub, mul, div2, div, is_larger, is_equal, add, sub,
--	binary2base, base2binary
--	bignum.barrett, bignum.mod, bignum.modpow

bignum = {};
bignum.new = function(base,sgn, digits)
	local ret = {};
	ret.base = base -- base of digit system
	ret.digits = {};
	ret.sgn = sgn -- sign of number,+1 or -1
	local data = ret.digits;
	local m = #digits;
	ret.digits = digits; -- THIS SEEMS TO MAKE A NEW COPY! if you work on this original wont change
	--for i=1,m do data[i] = digits[m-i+1] end -- copy
	return ret
end

bignum.rnd = function(base,sgn, length) -- random number
	local ret = {};
	for i =1,length do ret[#ret+1] = math.random(base)-1 end
	return bignum.new(base,sgn,ret)
end

bignum.tostring = function(n)
	local ret =  {};
	for i = #n.digits,1,-1 do ret[#ret+1] = n.digits[i] end
	return (n.sgn>0 and "" or "-") .. table.concat(ret,"'") .. "_" ..n.base
end

--n1 = bignum.new(10,-1,{5,7,3,1})
--say(bignum.tostring(n1))

bignum.importdec = function(ndec)
	local ret = {};
	local sgn = ndec>0 and 1 or -1;
	local base = 10;
	local n = ndec*sgn;
	local data = {};
	while n>0 do
		local r = n%base
		data[#data+1] = r;
		n=(n-r)/base
	end
	ret.base = base; ret.sgn = sgn; ret.digits = data;
	return ret
end

local importdec_test = function()
	local ndec = math.random(10^9);
	local n = bignum.importdec(ndec)
	say("importdec_test : " .. ndec .. " -> " .. bignum.tostring(n))
end
--importdec_test()

bignum.exportdec = function(n) -- warning: can cause overflow if number larger than 2^52 ~ 4.5*10^15
	local ndec = 0;
	for i = #n.digits,1,-1 do ndec = 10*ndec + n.digits[i] end
	return ndec*n.sgn
end

bignum.importhex = function(hex) -- nhex is string with characters 0-9(48-57) and a-f(97-102)
	local ret = {sgn=1,base = 16, digits = {}};
	local data = ret.digits;
	local length = string.len(hex);
	for i = length,1,-1 do
		local c = string.byte(hex,i)
		if c>=48 and c<=57 then
			data[length-i+1] = c-48
		elseif c>=97 and c<=102 then
			data[length-i+1]=c-97+10
		end
	end
	return ret
end

local importhex_test = function()
	local hex = "deadbeef";
	local n = bignum.importhex(hex)
	say(bignum.tostring(n))
end
--importhex_test()

bignum.exporthex = function(nhex) -- returns string with hex
	if nhex.base~=16 then return end
	local data = nhex.digits;
	local ret = {};
	for i = #data,1,-1 do
		local c = data[i];
		if c<10 then ret[#ret+1] =  string.char(48+c) else ret[#ret+1] =  string.char(97+c-10) end
	end
	return table.concat(ret,"")
end

local exporthex_test = function()
	local n = {sgn=1,base=16,digits = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}}
	say(bignum.exporthex(n))
end
--exporthex_test()

local base64c = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
"1","2","3","4","5","6","7","8","9","0","+","/"}
local base64n = {}; for i=1,#base64c do	base64n[base64c[i]]=i-1 end

bignum.exportbase64 = function(n)
	local binary = bignum.base2binary(n);
	local base64 = bignum.binary2base(binary,64);
	local data = base64.digits;	local ret = {};
	for i = #data,1,-1 do ret[#data-i+1] = base64c[data[i]+1] end
	return table.concat(ret,"")
end

bignum.importbase64 = function(base64,newbase)
	local digits = {}; local length = string.len(base64);
	for i = length,1,-1 do digits[length-i+1] = base64n[string.sub(base64,i,i)]	end
	local base64 = bignum.new(64,1,digits);
	local binary = bignum.base2binary(base64);
	return bignum.binary2base(binary,newbase);
end

local base64_test = function()
	local n = bignum.rnd(10,1,177);
	say("B   = " .. bignum.tostring(n))
	local b64 = bignum.exportbase64(n);
	say("B64 = " .. b64)
	local m = bignum.importbase64(b64,10)
	say("B   = " .. bignum.tostring(m))
end
--base64_test()

bignum.exportascii = function(n) -- 32 - 127 (96) -- problem with non even base
	local binary = bignum.base2binary(n);
	local ascii = bignum.binary2base(binary,96);
	local out = ascii.digits;
	local m = 32;local ret = {}; 
	for i = 1, #out do
		ret[#ret+1] = string.char(m+out[i])
	end
	return table.concat(ret,"")
end

bignum.importascii = function(text,newbase)
	local m = 32; -- ascii 32-127
	local digits = {}; local j = 1;
	for i=1, string.len(text) do 
		local c = string.byte(text,i)-m;
		if c>=0 and c<96 then digits[j] = c; j =j +1 end
	end
	local ascii = bignum.new(96,1,digits);
	local binary = bignum.base2binary(ascii);
	return bignum.binary2base(binary,newbase);
end

local ascii_test = function()
	local n = bignum.rnd(10,1,177); -- 512 bits
	say("B1     = " .. bignum.tostring(n))
	local ascii = bignum.exportascii(n);
	say("ascii = " .. ascii)
	local m = bignum.importascii(ascii,10)
	say("B2    = " .. bignum.tostring(m))
end
--ascii_test()

-----------------------------------------------
--	ADDITION
-----------------------------------------------


bignum._add = function(n1,n2,res) -- assume both >0, same base: n1+n2 -> res
	local b = n1.base;
	local m1 = #n1.digits;
	local m2 = #n2.digits
	local m = m1; if m2<m then m = m2 end
	local M = m1;if m2>M then M = m2 end
	
	local data1 = n1.digits; local data2 = n2.digits;
	res.digits = {} -- expensive?
	local data = res.digits; local carry = 0;
	for i = 1,M do
		local j = (data1[i] or 0) +(data2[i] or 0) + carry;
		if j >=b then carry = 1; j = j-b else carry = 0 end
		data[i] = j
	end
	if carry== 1 then data[M+1] = 1 end
	res.base = n1.base
end

local _add_test = function()
	local n1 = bignum.rnd(10,1,5)
	local n2 = bignum.rnd(10,1,5)
	local res = bignum.new(10,1,{})
	bignum._add(n1,n2,res)
	say("_add_test: " .. bignum.tostring(n1) .. " + " .. bignum.tostring(n2) .. " = " .. bignum.tostring(res))
end
--_add_test()

-----------------------------------------------
--	SUBTRACTION
-----------------------------------------------

bignum._sub = function(n1,n2,res) -- assume n1>n2>0, same base: n1-n2 -> res
	local b = n1.base;
	local m1 = #n1.digits;
	local m2 = #n2.digits
	local m = m1; if m2<m then m = m2 end
	local M = m1;if m2>M then M = m2 end
	
	local data1 = n1.digits; local data2 = n2.digits;
	res.digits = {};
	local data = res.digits; local carry = 0;
	local maxi = 0;
	for i = 1,M do
		local j = (data1[i] or 0) - (data2[i] or 0) + carry;
		if j < 0 then carry = -1; j = j+b else carry = 0 end
		if j~=0 then maxi = i end -- max nonzero digit
		data[i] = j
	end
	
	for i = maxi+1,M do	data[i] = nil end -- remove trailing zero digits if any
	res.base = n1.base
end

local _sub_test = function()
	local n1 = bignum.rnd(10,1,5)
	local n2 = bignum.rnd(10,1,5)
	local res = bignum.new(10,1,{})
	bignum._sub(n1,n2,res)
	say("_sub_test: " .. bignum.tostring(n1) .. " - " .. bignum.tostring(n2) .. " = " .. bignum.tostring(res))
end
--_sub_test()

bignum.is_equal = function(n1,n2) -- assume both >0, same base. return true if n1==n2
	local b = n1.base;
	local data1 = n1.digits; local data2 = n2.digits;
	if #data1~=#data2 then return false end
	for i =#data1,1,-1 do -- from high bits
		local d1 = data1[i];
		local d2 = data2[i];
		if d1~=d2 then return false end
	end
	return true -- all digits were ==
end

bignum.is_larger = function(n1,n2) -- assume both >0, same base. return true if n1>=n2
	local b = n1.base;
	local data1 = n1.digits; local data2 = n2.digits;
	if #data1>#data2 then return true elseif #data1<#data2 then return false end
	--remains when both same lentgth
	for i =#data1,1,-1 do -- from high bits
		local d1 = data1[i];
		local d2 = data2[i];
		if d1>d2 then return true elseif d1<d2 then return false end
	end
	return true -- all digits were >=, still larger
end

local is_larger_test = function()
	local n1 = bignum.rnd(10,1,5)
	local n2 = bignum.rnd(10,1,5)
	local res = bignum.is_larger(n1,n2);
	if res then res = "larger" else res = "smaller" end
	say("is_larger_test : " .. bignum.tostring(n1) .. " is ".. res .. " than "  .. bignum.tostring(n2))
end
--is_larger_test()

bignum.add = function(n1,n2,res) -- handle all cases, >0 or <0
	local sgn1 = n1.sgn;
	local sgn2 = n2.sgn;
	if sgn1*sgn2>0 then bignum._add(n1,n2,res); res.sgn = sgn1; return end -- simple case
	
	local is_larger = bignum.is_larger(n1,n2) -- is abs(n1)>abs(n2) ?
	local sgn = 1;
	if is_larger then sgn = sgn1 else sgn = sgn2 end
	
	if is_larger then 
		bignum._sub(n1,n2,res);
	else
		bignum._sub(n2,n1,res);
	end
	res.sgn = sgn
end

local add_test = function()
	local ndec1 = math.random(10^5) * (2*math.random(2)-3);
	local ndec2 = math.random(10^5) * (2*math.random(2)-3);
	
	local n1 = bignum.importdec(ndec1)
	local n2 = bignum.importdec(ndec2)
	local res = bignum.new(10,1,{})
	bignum.add(n1,n2,res)
	
	local resdec = bignum.exportdec(res);
	say("add_test: " .. bignum.tostring(n1) .. " + " .. bignum.tostring(n2) .. " = " .. bignum.tostring(res) .. " CHECK : " .. resdec-(ndec1+ndec2))
end
--add_test()

bignum.sub = function(n1,n2,res) -- handle all cases, >0 or <0
	--just add(n1,-n2)
	local sgn1 = n1.sgn;
	local sgn2 = -n2.sgn;
	if sgn1*sgn2>0 then bignum._add(n1,n2,res); res.sgn = sgn1; return end -- simple case
	
	local is_larger = bignum.is_larger(n1,n2) -- is abs(n1)>abs(n2) ?
	local sgn = 1;
	if is_larger then sgn = sgn1 else sgn = sgn2 end
	
	if is_larger then 
		bignum._sub(n1,n2,res);
	else
		bignum._sub(n2,n1,res);
	end
	res.sgn = sgn
end

local sub_test = function()
	local ndec1 = math.random(10^5) * (2*math.random(2)-3);
	local ndec2 = math.random(10^5) * (2*math.random(2)-3);
	
	local n1 = bignum.importdec(ndec1)
	local n2 = bignum.importdec(ndec2)
	local res = bignum.new(10,1,{})
	bignum.sub(n1,n2,res)
	local resdec = bignum.exportdec(res);
	say("sub_test: " .. bignum.tostring(n1) .. " - " .. bignum.tostring(n2) .. " = " .. bignum.tostring(res) .. " CHECK : " .. resdec-(ndec1-ndec2))
end
--sub_test()

-----------------------------------------------
--	MULTIPLY 
-----------------------------------------------

bignum.mul = function(n1,n2,res)
	
	local base = n1.base
	local sgn = n1.sgn*n2.sgn;
	
	local data1 = n1.digits; local m1 = #data1;
	local data2 = n2.digits; local m2 = #data2;
	
	res.digits = {}; res.base = base
	local data = res.digits; local m = m1+m2;
	
	local carry = 0
	for i = 1, m1 do
		-- multiply i-th digit of data1 and add to res
		local d1 = data1[i];
		carry  = 0
		for j = 1,m2 do
			local d2 = data2[j];
			local d = carry + d1*d2;
			local r =  (data[i+j-1] or 0) + d
			if r>=base then 
				data[i+j-1] = r % base; carry = (r - (r%base))/base 
			else 
				data[i+j-1] = r; carry = 0
			end
		end
		if carry>0 then data[i+m2] = carry % base end
	end
end

local mul_test = function()
	local ndec1 = math.random(10^8) 
	local ndec2 = math.random(10^8)
	
	local n1 = bignum.importdec(ndec1)
	local n2 = bignum.importdec(ndec2)
	local res = bignum.new(10,1,{})
	bignum.mul(n1,n2,res)
	local resdec = bignum.exportdec(res);
	say("mul_test: " .. bignum.tostring(n1) .. "*" .. bignum.tostring(n2) .. " = " .. bignum.tostring(res) .. " CHECK : " .. resdec-(ndec1*ndec2))
end
--mul_test()

-- m = 300, base 2^26, 100 repeats: amd ryzen 1200: 0.1s, amd-e350 apu 1.6ghz (2010) : 5.15s
mul_bench = function()
	local m = 300;
	local base = 2^26
	local r = 100
	
	local n1 = bignum.rnd(base, 1, m)
	local n2 = bignum.rnd(base, 1, m)
	local res = {digits = {}};
	local t = os.clock()
	for i = 1, r do	bignum.mul(n1,n2,res) end
	local elapsed = os.clock() - t;
	--say("n1 = " .. bignum.tostring(n1) .. ", n2 = " .. bignum.tostring(n2))
	say("mul benchmark. ".. m .. " digits, base " .. base .. ", repeats " .. r ..  " -> time " .. elapsed)
end
--mul_bench()

local exp_test = function()
	local n1 = bignum.importdec(2);
	local res1 = bignum.importdec(2);
	local res2 = bignum.importdec(1);
	
	local m=128
	for i = 1, m do
		bignum.mul(n1,res1, res2) -- n1*res1 = res2
		bignum.mul(n1,res2, res1) -- n1*res1 = res2
	end
	
	say("2^" .. (2*m) .. " = " .. bignum.tostring(res2) .. " CHECK " ..2^(2*m))

end
--exp_test()

-----------------------------------------------
--	DIVIDE
-----------------------------------------------

bignum.div2 = function(n,res) -- res = n/2, return n % 2. note: its safe to do: bignum.div2(res,res);
	
	local base = n.base;
	local data = n.digits; local m = #data;
	
	res.digits = {};
	local rdata = res.digits;
	local carry = 0
	
	local q = data[m]/2; 
	local fq = math.floor(q);
	if q~=fq then carry = base end
	if fq>0 then rdata[m] = fq else rdata[m]=nil end -- maybe digits shrink by 1?
	
	for i = m-1,1,-1 do
		local q = (data[i]+carry)/2;
		local fq = math.floor(q)
		if q~= fq then carry = base else carry = 0 end
		rdata[i] = fq;
	end
	if carry ~= 0 then return 1 else return 0 end
end
	
local div2_test = function()
	local ndec1 = math.random(10^8) 
	local n1 = bignum.importdec(ndec1)
	local res = bignum.new(10,1,n1.digits)
	bignum.div2(res,res) -- res = res/2
	
	say("div2_test: n1/2 = " .. bignum.tostring(n1) .. "/2 = " .. bignum.tostring(res) .. " = res")
	local rescheck = bignum.new(10,1,{})
	bignum._add(res,res,res);bignum._sub(n1,res, res);
	
	say("CHECK: n1-2*res = " .. bignum.tostring(res))
	
end

--div2_test()

--[[
	very simple division that works reasonably well (we only need 1 division for barrett reduction anyway, could use precomputed too)
	
	strategy: bisection for f(x) = x*D + comparison with N, takes around Log_2(initial range) steps (sums+mults), 
		so ~O(D^2*log base^(n2-n1))
		low, mid, high. pick reasonably good initial range guess, like near order of magnitude close.
		mid =  (low+high)/2
		compute: compare N and mid*D, if N bigger then low = mid else high = mid..
	BENCHMARKS: (amd ryzen 1200)
		HUGE N=10k bit number/ D=5k bit number : 1.5 s
		N = 8k bit number / D = 4k bit number : 0.7s
		N = 1040 bit, D = 520 bit: 0.0042 s ( typical application srp,diffie-hellman in Z_~2^512 group)
		if D is 3900 bits it takes around 3900 steps of iteration
			amd-e350 apu 1.6ghz (sep 2010)
				N = 8k bit, D = 4k bit, divide takes 44s ( 60x slower than ryzen)
			AMD Dual Core E2-1800 (july 2012)
				N = 8k bit, D = 4k bit, 5.25s
	TODO: 
		possible speed improve ?: after there are some digits correct
		reduce N by N = N-q0*D which will effectively decrease N and multiplies of mid ( smaller numbers ). then keep adding 
		obtained q's together to get final quotient.
		
	--]]

bignum.div = function(N,D, res) -- res = [N/D]
	
	local base = N.base;
	res.base = base
	res.digits = {}; 
	local data = res.digits; 
	
	local n1 = #N.digits;local n2 = #D.digits;
	-- trivial cases, prevent wasting time here
	if n1<n2 then res.digits = {0}; return end -- clearly N<D
	if n2 == 1 and D.digits[1] == 1 then res.digits = N.digits return end -- division by 1!
	
	local low = bignum.new(base,1,{})
	local high = bignum.new(base,1,{})
	-- better initial range for less needed iterations
	local ldigits = low.digits;local hdigits = high.digits;
	for i = 1,n1-n2 do ldigits[i]=0;hdigits[i]=0 end
	ldigits[n1-n2]=N.digits[n1];hdigits[n1-n2+1] = ldigits[n1-n2];
	--say("low " .. bignum.tostring(low) .. " high " .. bignum.tostring(high))
	
	local mid = bignum.new(base,1,{});
	local temp = bignum.new(base,1,{});
	local step = 0;
	
	while step < 100000 do -- in practice this uses around log_2 (base^(n2-n1)) iterations, for example dividing 8192 bit number by 4096 takes ~4000 iterations..
		step = step + 1
		bignum._add(low,high,mid); bignum.div2(mid,mid); -- mid = (low+high)/2
		
		if bignum.is_equal(low,mid) then 
			if DEBUG then say("DONE. step  " .. step) end-- .. " low = " .. bignum.tostring(low) .. " high = " .. bignum.tostring(high) .. " mid = " .. bignum.tostring(mid))
			res.digits = mid.digits
			return
		end

		bignum.mul(D, mid, temp) -- temp = D*mid
		if bignum.is_larger(N,temp) then low.digits = mid.digits else high.digits = mid.digits end
	end
end


local div_test = function()
	local ndec1 = math.random(10^8) 
	local n1 = bignum.importdec(ndec1)
	local ndec2 = math.random(10^6)
	local n2 = bignum.importdec(ndec2)
	
	local res = bignum.new(10,1,{})
	bignum.div(n1,n2,res)
	
	local temp = bignum.new(10,1,{})
	bignum.mul(n2,res,temp);bignum._sub(n1,temp,temp) -- temp = n1 - n2*res
	
	say(ndec1/ndec2)
	say("n1/n2 =  " .. bignum.tostring(n1) .. " / " .. bignum.tostring(n2) .. " = res = " .. bignum.tostring(res) .. ", residue n1-n2*res = " .. bignum.tostring(temp) .. (bignum.is_larger(n2,temp) and " (IS SMALLER THAN n2) " or " FAIL."))
end
--div_test()

local divbignum_test = function()
	local m = 300;
	local base = 2^26
	local n1 = bignum.rnd(base, 1, m)
	local n2 = bignum.rnd(base, 1, m/2)
	local res = {sgn=1, digits = {}};
	DEBUG = true -- to display how many steps were needed
	local t = os.clock();bignum.div(n1,n2,res); local elapsed = os.clock() - t;
	DEBUG = false
	local temp = {sgn=1, digits = {}};
	bignum.mul(n2,res,temp);bignum._sub(n1,temp, res); -- res = n1-n2*res
	if bignum.is_larger(n2, res) then 
		say("divbignum_test : residue n1 - n2*res is smaller than n2. OK.") 
	else
		say("divbignum_test : residue n1 - n2*res is NOT smaller than n2. FAIL.") 
	end
end

--divbignum_test()

div_bench = function()
	local m = 300;
	local base = 2^26
	local r = 1
	
	local n1 = bignum.rnd(base, 1, m)
	local n2 = bignum.rnd(base, 1, m/2)
	local res = {sgn=1, digits = {}};
	local t = os.clock()
	for i = 1, r do	bignum.div(n1,n2,res) end
	local elapsed = os.clock() - t;
	say("n1 = " .. bignum.tostring(n1) .. "\nn2 = " .. bignum.tostring(n2) .. "\nn1/n2 = "  .. bignum.tostring(res))
	say("div benchmark. n1 (".. m .. " digits ( " .. 26*m .." bits)), n2 (" .. m/2 .. " digits), base " .. base .. ", repeats " .. r ..  " -> time " .. elapsed)
end

--div_bench()

bignum.base2binary = function(_n)
	local base = _n.base;
	local n = {sgn = 1, base = base, digits = _n.digits }
	local data = n.digits;
	local i = 0;
	local out =  {};
	while (#data > 1 or (#data==1 and data[1] > 0)) do -- n>0
		i=i+1
		out[i]  = bignum.div2(n,n); data = n.digits;
	end
	return {sgn=1,base = 2, digits = out}
end

local base2binary_test = function()
	local base = 10;
	local m = 2;
	local n = bignum.rnd(base, 1, m)
	local nb = bignum.base2binary(n);
	say(bignum.tostring(n) .. " -> " .. bignum.tostring(nb))
end
--base2binary_test()


bignum.binary2base = function(n, newbase) -- newbase must be even
	local base = n.base;
	local ret = {sgn=1,base=newbase, digits = {0}}
	local out = ret.digits
	local data = n.digits
	for i = #data,1,-1 do
		bignum._add(ret,ret,ret) -- ret = 2*ret
		out = ret.digits
		out[1]=out[1]+ data[i]; -- WARNING: basically +1, if newbase is even no carry, else more complication here
	end
	return ret
end

local binary2base_test = function()
	local base = 10;
	local m = 4;
	local nb = bignum.rnd(2, 1, m)
	local n = bignum.binary2base(nb,base);
	say(bignum.tostring(nb) .. " -> " .. bignum.tostring(n))
end
--binary2base_test()


-----------------------------------------------
--	MODULAR MULTIPLY
-----------------------------------------------

-- a,b in Z_n -> a*b mod n = ?
-- how to compute a % n efficiently? We can use barrett reduction trick.
-- normally: a%n = a - [a/n]*n. Instead of division we compute [a/n] with multiply and shift ( base = b)
-- [a/n] = [a*(B^k/n)/B^k] = [a*m/B^k]. Here integer m is [B^k/n] for some k, where B^k>=n. since
-- a*(m/B^k-1/n) < 1 we get a*(m-B^k/n) < B^k or m-B^k/n < B^k/a. since left side is always <1 this will be true if 
-- 1 < B^k/a or a < B^k. note since a*m/B^k - a/n < 1 after applying [ ] we can still get difference = 1 (but not more),
-- so need to check if  a - [a*m/B^k]*n is smaller than n. If not additional -n is needed.
-- so REQUIREMENTS: n<=B^k, a< B^k.
-- if we need a<n^2 (like in modulo multiply in Z_n) then this means: (n-1)^2 < B^k. So if n<B^N then k should be 2N.

-- barret = {n = bignum,  m =  from barrett.., k= .., }
-- returns barrett data. used to cheaply compute a/n without division as bitshiftright_k(a*m) + possible 1, where a <= (n-1)^2
bignum.get_barrett = function(n) 
	local base = n.base;
	local k = 2*#n.digits+2; -- n<B^(n1+1) -> k = 2*(n1+1)
	local Bk = bignum.new(base,1,{})
	local res = bignum.new(base,1,{})
	local data = Bk.digits;
	for i =1,k do data[i]= 0 end; data[k+1]=1; -- this is B^k
	bignum.div(Bk, n,res);
	return {n=n, m=res, k=k};
end

local get_barrett_test = function()
	local d=4
	local ndec2 = math.random(10^d) 
	local n2 = bignum.importdec(ndec2)
	local barrett = bignum.get_barrett(n2)
	local barrettm = math.floor(10^(2*d+2)/ndec2)
	say(bignum.tostring(barrett.m) .. "(CHECK: " .. barrettm .. ")")
end
--get_barrett_test()

-- mod using barrett. possible improvement: montgomery.
bignum.mod = function(a,barrett,res) -- a should be less or equal (n-1)^2, stores a%n into res
	
	local k = barrett.k;
	local n = barrett.n;
	local m = barrett.m;
	local base = a.base;
	
	bignum.mul(a,m,res); -- large multiply 1: res = a*m

	local data = res.digits;local n1 = #data;  --res = res / B^k
	for i = 1, n1-k do data[i]=data[i+k] end; for i = n1-k+1,n1 do data[i] = nil end -- bitshift
	
	local temp = bignum.new(base,1,{});
	bignum.mul(res,n, temp); -- multiply 2: res*n
	bignum._sub(a,temp,res); -- subtract: res = a - res*n
	if bignum.is_larger(res,n) then bignum._sub(res,n,res) end
end

local mod_test = function()
	local m = 3;
	local base = 10;
	local n1 = bignum.rnd(base, 1, 2*m)
	local n2 = bignum.rnd(base, 1, m)
	local barrett = bignum.get_barrett(n2)
	local res = bignum.new(base,1,{});
	bignum.mod(n1, barrett, res);
	local is_larger = bignum.is_larger(n2,res);
	
	say("barrett mod_test: n1 " .. bignum.tostring(n1) .. " n2 " .. bignum.tostring(n2) .. " res = n1 % n2 = " .. bignum.tostring(res) .. " CHECK: res<n2 " .. (is_larger and "OK" or "FAIL") )
	
end
--mod_test()

--  computing a^b mod n using modular exponentiation : 
--  1. suppose we have b = sum_i b_i*2^i ( binary expansion). Then a^b = prod_i a^(2^i) a^b_i.
-- 		we start from low bits and multiply with new term each step. we compute a^(2^i) mod n iteratively, with a = a^2 mod n.
--		In each step if b_i == 1 we multiply with a. Work: 2-3 multiplies each step
--  2. we could first compute all b_i and then start from high end ( like efficient polynomial evaluate):
--  	res = res^2*a^(b_i) mod n . work (1-2 multiplies per step + all b_i).
--	3. sliding window. works like 2 but it uses binary representation of b and does larger parts (window size k) at once. Window it
--		uses is of the form 1xxxxxxxx1, where total length less than prescribed k. Potentially k* faster but with precompute of 2^k-1 values

-- method 1 
bignum.modpow = function(a_,b_,barrett) -- efficiently calculate a^b mod n, need log_2 b steps
	local base = a_.base
	local a = bignum.new(base,1,a_.digits); -- base
	local b = bignum.new(base,1,b_.digits); -- exponent
	local bdata = b.digits;
	
	local ret = bignum.new(base,1,{1});
	local temp = bignum.new(base,1,{});
	
	while (#bdata > 1 or (#bdata==1 and bdata[1] > 0)) do -- b>0
		if bdata[1] % 2 == 1 then
			bignum.mul(ret, a, temp) 
			bignum.mod(temp,barrett, ret) -- ret = a*ret % n
		end
		bignum.div2(b,b); bdata = b.digits -- b = b/2
		
		bignum.mul(a,a,temp);bignum.mod(temp,barrett, a) -- a=a^2 % n
	end
	return ret
end

-- times: base 2^26. 
-- 	ryzen 3 1200: m=150 (4000 bits): 7.2s, m=80(2080bits): 1.1s,  m=40: 0.14, m = 30: 0.07, m = 20: 0.028
-- 	amd-e350 apu 1.6ghz (2010), m = 20: 0.59s, m = 40: 6.28s
DH_bench = function() -- test for modpow with diffie-hellman key exchange
	local m = 40;
	local bits = 26
	local base = 2^bits;
	local a = bignum.rnd(base, 1, m)
	local b = bignum.rnd(base, 1, m)
	local c = bignum.rnd(base, 1, m)
	local n = bignum.rnd(base, 1, m)
	
	local t = os.clock()
	local barrett = bignum.get_barrett(n) -- precompute this from modulo n
	local t1 = os.clock(); say("barret pre computation : " .. t1-t);t=t1
	
	local resb = bignum.modpow(a,b, barrett); -- efficient modular a^b using barrett reductions
	t1 = os.clock();say("resb = modpow(a,b) : " .. t1-t);t=t1
	
	local resc = bignum.modpow(a,c, barrett); -- a^c
	t1 = os.clock();say("resc = modpow(a,c) : " .. t1-t);t=t1
	
	local resbc = bignum.modpow(resb,c, barrett); -- (a^b)^c
	t1 = os.clock();say("resbc = modpow(resb,c) : " .. t1-t);t=t1
	
	local rescb = bignum.modpow(resc,b, barrett); -- (a^c)^b
	t1 = os.clock();say("rescb = modpow(resc,b) : " .. t1-t);t=t1
	
	say("DH benchmark: (a^b)^c = " .. bignum.tostring(resbc) .. "\nCHECK equality (a^b)^c == (a^c)^b : " .. (bignum.is_equal(resbc,rescb) and "OK" or "FAIL"))
	say("settings: base " .. base .. ", digits " .. m .. " (" ..  m*bits .." bits )")
end
DH_bench()

-- note: DH security ( log problem ) can be solved for 512 bit by expert team, 1024 prime modulo for state actors ( logjam attack, "Imperfect Forward Secrecy:
--	How Diffie-Hellman Fails in Practice", Oct 2015

self.remove() -- prevent loop in robot csm