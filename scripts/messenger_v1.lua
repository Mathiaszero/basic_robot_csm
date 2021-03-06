--MSGER by rnd
--[[ 
INSTRUCTIONS:

1.	set target player name bellow and encryption = true ( otherwise not encrypted)
2. start program and wait for session key or send one (hold W+S)
3.	to send message just write: ,hello

--]]

if not init then
	msgversion = "05042018a"
	--- S E T T I N G S ---------------------------------------
	target = "test" --write name of player you want to talk to
	privatemsg = true -- false to chat, true for private msg

	ack_timeout = 5; -- timeout after sending initial packet
	state = 0; -- if sendkey:  0: sending key, 1: key receipt aknowledged, ready.  if receieve key: 0: waiting for key, 1: ready
	chatchar = "''" -- some servers end msg announce with :, some with %)
	
	password = { -- ~30 bits per row, 10x ~ 300 bit, 2 consecutive passwords should be different!
		1728096374, 
		1301007001,
		1000050002,
		1040053203,
		1000000004,
		1000600005,
		1080156086,
		1047302203,
		1800100228,
		1480500509,
	}
	
	password0 = {}; for i=1,#password do password0[i] =  password[i] end
	
	
	-- each password can be up to 10^10, plus random session key 4*10^13 for total 64*10^43 ~ 148.8 bits
	-----------------------------------------------------------
	
	init = true
	say(minetest.colorize("lawngreen","#MESSENGER ".. msgversion .. " STARTED. Starting conversation with " .. target))
	
	say(minetest.colorize("orange","wait for receipt of session key or hold W+S to send session key!"))
	
	
	self.msg_filter(chatchar) -- only records messages that contain chatchar to prevent skipping if too many messages from server!
	
	empty_chat_buffer = function()
		local msg = "";	while msg do msg = self.listen_msg() end
	end
	empty_chat_buffer();
	
	
	maxn = 1000000000;
	
	rndm = 2^31 − 1; --C++11's minstd_rand
	rnda = 48271; -- generator
	random = function(n)
		rndseed = (rnda*rndseed)% rndm;
		return rndseed % n
	end
	
	rndseed = os.time(); session_key = random(maxn) -- derive session key
	send_session_key = false
	state = -1
	
	scount = 0
	wtime = 0	
	
	encrypt_ = function(input,password,sgn)
		local n = 128-32+1; -- Z_97, 97 prime
		local m = 32;
		local ret = {};input = input or "";
		rndseed = password;
		local key = {};
		local out = {};
		for i=1, string.len(input) do 
			key[i] = random(n) -- generate keys from password
			out[i] = string.byte(input,i)-m
			if out[i] == -6 then out[i] = 96 end -- conversion back
		end
		
		if sgn > 0 then -- encrypt
			
			for i=1, string.len(input) do
				local offset=key[i]
				local c = out[i];
				
				local c0 = 0;
				for j = 1,i-1 do c0 = c0 + (out[j])^3; c0 = c0 % n end
				for j = i+1,string.len(input) do c0 = c0 + (out[j])^3; c0 = c0 % n end
				
				c = (c+(c0+offset)*sgn) % n;
				out[i] = c
			end
		else -- decrypt
			local c0 = 0
			for i = string.len(input),1,-1 do
				local offset=key[i];
				local c = out[i];

				local c0 = 0;
				for j = 1,i-1 do c0 = c0 + (out[j])^3; c0 = c0 % n end
				for j = i+1,string.len(input) do c0 = c0 + (out[j])^3; c0 = c0 % n end
				
				c = (c+(c0+offset)*sgn) % n;
				out[i] = c
			end
		end
		
		
		for i = 1, string.len(input) do
			if out[i] == 96 then out[i]=-6 end -- 32 + 96 = 128 (bad char)
			ret[#ret+1] = string.char(m+out[i])
		end
		
		return table.concat(ret,"")
	end
		
	
	encrypt = function(text,password)
		local input = text;
		local out = "";
		for i = 1, #password do
			input = encrypt_(input,password[i], (i%1)*2-1)
		end
		return input
	end
	
	decrypt = function(text, password)
		local input = text;
		local out = "";
		for i = #password,1,-1 do
			input = encrypt_(input,password[i], -(i%1)*2+1)
		end
		return input
	end
	
	
	unit_test = function()
		local text = "Hello encrypted world! 12345 ..."
		--local password = {1,2,session_key}
		local enc = encrypt(text,password)
		local dec = decrypt(enc,password)
		say(text .. " -> " .. enc .. " -> " .. dec)
		self.remove()
	end
	--unit_test()
end


if state == -1 then -- idle
	msg = self.listen_msg()
	if msg then
		if string.find(msg,target) and string.find(msg,chatchar) then
			msg = minetest.strip_colors(msg)
			local i = string.find(msg, chatchar)
			if i then -- ready to chat
				msg = string.sub(msg,i+string.len(chatchar))
				session_key =  tonumber(decrypt(msg,password0))
				if not session_key then 
					say(minetest.colorize("red","#MESSENGER: target uses wrong password! restarting...")) init = false 
				else
					msg = encrypt("OK " .. session_key, password0)
					say("/msg " .. target .. " " .. chatchar .. msg,true) -- send confirmation of receipt
					msg = false
					state = 1 scount = 1
					say(minetest.colorize("lawngreen","#MESSENGER: RECEIVED SESSION KEY " .. session_key))
					password[1] = session_key;password[#password] = password0[#password0] - session_key;
					--say(password1 .. " " .. password2)					
				end
			end 
		end
	end
	
	if not msg and minetest.localplayer:get_key_pressed() == 3 then 
		say(minetest.colorize("red","SENDING SESSION KEY TO " .. target))
		state = 0;
	end
else -- receive/send
	msg = self.listen_msg()
	
	if state == 0 then 
		if minetest.localplayer:get_key_pressed() == 3 then scount = 0 wtime = 0 end
		if scount == 0 then msg = "" end -- trigger sending key at start
	
		wtime = wtime + 1
		if wtime > ack_timeout then say(minetest.colorize("red","#MESSENGER: timeout while waiting for response from target. resetting")); init = false end
	end
	
	if msg then
		if state == 0 then
			
			-- SENDING KEY, listening for confirmation
			if string.find(msg,target) and string.find(msg,chatchar) then -- did we receive confirmation?
				msg = minetest.strip_colors(msg)
				local i = string.find(msg, chatchar)
				if i then 
					msg = string.sub(msg,i+string.len(chatchar))
					msg = decrypt(msg,password0) 
					if msg == "OK " .. session_key then  -- ready to chat
						state = 1
						say(minetest.colorize("lawngreen","#MESSENGER: TARGET CONFIRMS RECEIPT OF SESSION KEY " .. session_key))
						password[1] = session_key;password[#password] = password0[#password0] - session_key;
						--say(password1 .. " " .. password2)
					end
				end
			elseif scount == 0 then -- send session key
				scount = 1
				msg = encrypt(session_key, password0)
				say("/msg " .. target .. " " .. chatchar .. msg,true)
				say(minetest.colorize("red","#MESSENGER: waiting for " .. target .. " to respond ..."))
				wtime = 0
			end
		elseif state == 1 then -- NORMAL OPERATION: DECRYPT INCOMMING MESSAGES, SEND ENCRYPTED MESSAGES
			if string.find(msg,target) and string.find(msg,chatchar) then
				--say("D1")
				msg = minetest.strip_colors(msg)
				local i = string.find(msg, chatchar)
				if i then 
					msg = string.sub(msg,i+string.len(chatchar))
					--say("ENCRYPTED :" .. msg)
					
					msg = decrypt(msg,password);
					if string.byte(msg,1)~=32 then 
						say(minetest.colorize("red","#MESSENGER: DECRYPTION ERROR. TARGET USING DIFFERENT PASSWORD. RESTARTING MESSENGER."))
						init = false
					end
					
					
					if string.sub(msg,2,2)=="$" then
						form = "size[5,5] textarea[0,0;6,6;MSG;MESSAGE FROM " .. target .. ";" .. minetest.formspec_escape(msg) .. "]"
						minetest.show_formspec("robot", form) 
					else 
						msg = minetest.colorize("LawnGreen","DECRYPTED from " .. target .. ">") .. minetest.colorize("yellow", msg) 
						say(msg) 
					end
				end
			end

		end
	end
end

msg = self.sent_msg() -- is there message to send?
if msg then
	say(minetest.colorize("Pink", "MESSAGE SENT to " .. target .. "> " .. msg))
	msg = encrypt(" " .. msg, password)
	if privatemsg then
		say("/msg " .. target .. " " .. chatchar .. msg,true)
	else
		say(chatchar .. msg,true)
	end
end