-- rnd key exchange v2 (improved key hide when doing verification)
-- v05152018

if not crypto then
	
	crypto = _G.crypto; bignum = _G.bignum;

	-- generate safe prime in openssl: openssl prime -generate -safe -bits 512 -hex
	-- then import it here

	local importsshprime = function(GH, base)
		local G1 = bignum.importhex(GH); local G2 = bignum.base2binary(G1);
		local G3 = bignum.binary2base(G2,base);return minetest.serialize(G3.digits)
	end

	--GH = "";local code = importsshprime(GH,2^26)
	--local form = "size[5,5] textarea[0,0;6,6;MSG;MESSAGE;" .. minetest.formspec_escape(code) .. "]"
	--local t = os.clock();local barrett = bignum.get_barrett(p512);say(os.clock()-t) -- precompute barrett form
	--local code = minetest.serialize(barrett)
	--minetest.show_formspec("robot", form)

	--512 bit
	--c1d3a133c9b3720da868dda10b6a0bde0e1a47d797d3e02f2673157ad26c33970553352abd72114a48813b3f1a3d86120c2150d9c33780bf0ce31acf2e28b813
	p512 = {
		base = 2^26, sgn = 1,
		digits = {198478,34815131,14451562,6872481,2992175,31515044,32892404,65023782,30168555,19317561,29447373,19578226,4532514,1291249,42951044,34349392,57085150,782542,13022155,36222995}
		}
		
	barrett512 = {
		["k"] = 42, ["m"] = {["base"] = 67108864, ["sgn"] = 1, 
		["digits"] = {35898149, 41794076, 18684097, 46016930, 38889135, 63030343, 34383953, 50385002, 5837211, 26975470, 58748693, 26637596, 30851364, 25453708, 59604851, 52048498, 48309457, 2932823, 30408552, 42076151, 59509517, 57220987, 1}}, ["n"] = {["base"] = 67108864, ["sgn"] = 1, ["digits"] = {198478, 34815131, 14451562, 6872481, 2992175, 31515044, 32892404, 65023782, 30168555, 19317561, 29447373, 19578226, 4532514, 1291249, 42951044, 34349392, 57085150, 782542, 13022155, 36222995}}
		}

	--2048 bit
	--db726369acb4a51666ee14e0dc4305afc11692cc0dfa9d06b399ebc7b541b095ca3f48633ed936e0d4633af1c8b72886829c5fdd98861c44acdadc54075dc3beeb3d4a4bf9fb13b2c943e8bcb8c8df4440a84753c87d1512ff3db5083941ac88764c674da50771fdd7f4db99d7281e653253191df1f0137004b81488ecf9d15c49462c5438d4c060fa5a36e3e8e73ca1969d312b1b11df3e6fa3ce0a87641f4007884470d4911da45df914143c2c446a51443d6595c84cf83467825cf08007546e04c5137acac3ec0f413c522f5904d3b5230b4f5f2a26a0a8ad318ab541d1cd69079b0cb040827e2eb48f4fb7bc76623b96c7d38c603a186e24ae70a3bd66b3
	p2048 = {
		base = 2^26, sgn = 1,
		digits = {62744243, 19635240, 60917474, 55456128, 37459655, 32447896, 55112955, 34207930, 51163200, 56246758, 55844124, 45401642, 36085928, 47437770, 20664880, 12411923, 54606930, 45153027, 5322668, 22132755, 15761415, 18473111, 8703875, 16094807, 6967620, 17763089, 31428929, 38041233, 4485332, 63963618, 11040321, 29265720, 51502910, 55331526, 63576425, 59745180, 16407094, 37040152, 6473027, 54882597, 8973561, 77317, 52363575, 21783671, 1991986, 48657866, 64847693, 43261383, 38561613, 7021085, 55608212, 4979958, 63470869, 2757076, 9303108, 61010659, 62048579, 50233028, 45339812, 24579835, 47993863, 51456822, 31033441, 34238847, 12003462, 13548658, 57544006, 26016612, 30031688, 22047781, 27180155, 41163470, 46927354, 66078116, 29634650, 62411651, 10819174, 14314285, 898854}
		}
		
	barrett2048 = {
		["k"] = 160, ["m"] = {["base"] = 2^26, ["sgn"] = 1, 
		["digits"] = {52173231, 58926316, 7134135, 58005281, 29642925, 1996, 43704342, 19181367, 51834951, 40753938, 5670116, 25083444, 53681109, 39194353, 21018693, 16186348, 52641345, 34474171, 45582158, 65632598, 6663244, 17715531, 46582518, 715815, 35941432, 62741031, 14063905, 37500214, 33724930, 25815530, 29521098, 42349641, 30021354, 56331771, 20197595, 44642351, 39774, 15935544, 18538053, 54085894, 20262092, 170794, 877950, 7075184, 15922733, 42275553, 19627281, 61124663, 6351068, 20488035, 52369744, 26751026, 17905178, 25990200, 47243983, 42954366, 65859731, 23375626, 40610711, 9951837, 9139091, 55630155, 4911180, 17490059, 43409254, 37055369, 1417704, 12145177, 9055946, 41623298, 33230333, 1111792, 21966597, 20877280, 44498082, 6831928, 22418430, 4437100, 27282748, 12568457, 44322344, 74}}, ["n"] = {["base"] = 67108864, ["sgn"] = 1, ["digits"] = {62744243, 19635240, 60917474, 55456128, 37459655, 32447896, 55112955, 34207930, 51163200, 56246758, 55844124, 45401642, 36085928, 47437770, 20664880, 12411923, 54606930, 45153027, 5322668, 22132755, 15761415, 18473111, 8703875, 16094807, 6967620, 17763089, 31428929, 38041233, 4485332, 63963618, 11040321, 29265720, 51502910, 55331526, 63576425, 59745180, 16407094, 37040152, 6473027, 54882597, 8973561, 77317, 52363575, 21783671, 1991986, 48657866, 64847693, 43261383, 38561613, 7021085, 55608212, 4979958, 63470869, 2757076, 9303108, 61010659, 62048579, 50233028, 45339812, 24579835, 47993863, 51456822, 31033441, 34238847, 12003462, 13548658, 57544006, 26016612, 30031688, 22047781, 27180155, 41163470, 46927354, 66078116, 29634650, 62411651, 10819174, 14314285, 898854}}
		}

	password0 = {123456789}; -- cosmetics only
	
	local DH_2048_test = function()
		local base = 2^26
		-- order of element in Z_p* must divide |Z_p*|= p-1. since p is safe prime, p-1=2q for prime q. so either order is 2 or q.
		local g = bignum.new(base, 1, {2}) -- order of this is obviously not 2, so its (p-1)/2
		local m = 80; -- 80*26 = 2080 bit exponent
		local b = bignum.rnd(base, 1, m)
		local c = bignum.rnd(base, 1, m)

		local t = os.clock();
		local resb = bignum.modpow(g,b, barrett2048); -- g^b mod p2048
		say("g^b time " .. os.clock()-t)
		local resc = bignum.modpow(g,c, barrett2048); -- g^c mod p2048
		say("g^c time " .. os.clock()-t)
		local resbc = bignum.modpow(resb,c, barrett2048); -- g^bc mod p2048
		say("g^bc time " .. os.clock()-t)
		local rescb = bignum.modpow(resc,b, barrett2048); -- g^cb mod p2048
		say("g^cb time " .. os.clock()-t)
		if bignum.is_equal(resbc,rescb) then say("equality check g^bc = g^cb PASSED.") else say("equality check g^bc = g^cb FAILED.")end
		say(os.clock()-t)
	end
	--DH_2048_test()

	local rndexchange_test = function()
		local base = 2^26;
		local g = bignum.new(base, 1, {2})
		local m = 20; -- 20*26 = 520 bits
		local t = os.clock();
		
		local x = bignum.rnd(base, 1, m) -- use better randomseeds for real one
		local v = bignum.modpow(g,x,barrett512); -- 'public' key that A(client alice) and B(server) both know.
		say("RND KEY EXCHANGE PROTOCOL v2")
		say("0. PUBLIC KEY v = " .. bignum.tostring(v))
		
		-- 		1. B picks random r and tells A y=g^r+v. 
		local r = bignum.rnd(base,1,m);	local gr = bignum.modpow(g,r,barrett512);
		local y = bignum.new(base,1,{}); bignum._add(gr,v,y); -- send y to other party
		say("    1.1 B sends A: y = " .. bignum.tostring(v))
		say("2. IF CONFIRM IDENTIY : A confirms identity by sending back hash((y-v)^x) = hash(v^r) = hash(g^rx) to prove to B he know x.")
		local temp = bignum.new(base,1,{});	bignum._sub(y,v,temp); 
		local yvx = bignum.modpow(temp, x, barrett512)
		say("    2.1 A computes (y-v)^x = " .. bignum.tostring(yvx))
		say("        hash = " .. crypto.rndhash(bignum.tostring(yvx),512))
		-- 
		local vr = bignum.modpow(v, r, barrett512)
		say("    2.2 B computes v^r = " .. bignum.tostring(vr))
		say("        hash = " .. crypto.rndhash(bignum.tostring(vr),512))
		
		if bignum.is_equal(vr,yvx) then say("equality check PASSED.") else say("equality check FAILED.") end
		say("3. SESSION KEY K=g^rx = (y-v)^x =  v^r = " .. crypto.rndhash(" " .. bignum.tostring(vr),256))
		
		say("time " .. os.clock()-t)
	end
	--rndexchange_test()
	
	self.remove()
end

-- auth + key exchange in one idea: A alice (client), B bob (server)
-- key generation: A generates its shared secret as v = g^x for secret random x and exchanges it with B. 
-- this initial exchange can use DH with very large group to prevent any snooping.

-- verification: 
-- 		1. B picks random r and tells A y=g^r+v. 
--			Note here that listeners only see g^r+v so they have no clue what v is or what g^r is. Even from multiple sessions they
--			learn nothing if g is generator of whole group and r truly random, since then g^r can be 'anything' with same probability.
-- 		2. A confirms identity by sending back hash(g^rx) = hash(v^r) = hash((y-v)^x) to prove you know a. 
-- 		3. shared secret is then another hash of K=g^rx = (g^r)^x =  (g^x)^r.

--
-- basic idea is this: i tell you y=g^r for random r, you need to tell me y^x, so i believe you know x. But hide y by adding v and with hash so
-- listeners dont get any clues.

--observations: 
-- 0. note that K lies in potentially smaller group generated by g^x, srp 6a is better here since for srp K = g^(b(a + ux)).
-- 		where a,b are random
-- 		The order of Z_p* is 2q for prime q, where p-1 = 2q ( p safe prime ). Order of g^x is either 2  or q or 2q (if (g^x)^2~= 1 then its not 2)
-- 		So order of g^x is still (p-1)/2 in this case.
-- thm: if G is finite group then order of any element divides |G|. Furthermore, if p is prime dividing |G| there exists element
-- in G of order p (cauchy thm)

-- 1. Suppose there is observer C. first time of interaction he can see v=g^x sent from  A to B, but getting x is not possible ( log problem )
-- 2. later C can see B send v+g^r, and if he doesnt know v already this does not reveal it to him.. If we encrypt this this might introduce
-- 		weakness if not properly done, cause only good password would encrypt to number, bad password would be random mess.

-- WEAKNESS: if C knows v ...?
-- idea: first time exchange uses larger DH group for more safety to exchange: v = g^x to prevent C from learning x.

--srp v6a : http://srp.stanford.edu/design.html
--NOTE: srp v1 http://srp.stanford.edu/design1.html used weak approach to compute secret: S = (Wp*Xp)^Ys, where Xp = could be leaked 
-- pass. verifier, Wp = controlled by client, Ys = random server secret
-- if rogue client know Xp he could select Wp so that Wp*Xp becomes value of his choice, hence controlling what the final shared secret
-- will be.
-- rnd key exchange v2 does not have that weakness. even if rogue learns v = g^x by other means he still needs to solve log problem for x.