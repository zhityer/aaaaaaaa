HTTP = require('socket.http')
HTTPS = require('ssl.https')
URL = require('socket.url')
JSON = require('dkjson')

version = '3.0.1'

bot_init = function() -- The function run when the bot is started or reloaded.
         pppppppppppppppppppppppppppppppp
	config = dofile("config.lua") -- Load configuration file.
	dofile("bindings.lua") -- Load Telegram bindings.
	dofile("utilities.lua") -- Load miscellaneous and cross-plugin functions.

	bot = nil
	while not bot do -- Get bot info and retry if unable to connect.
		bot = getMe()
	end
	bot = bot.result

	plugins = {} -- Load plugins.
	for i,v in ipairs(config.plugins) do
		local p = dofile("plugins/"..v)
		table.insert(plugins, p)
	end

	print('@'..bot.username .. ', AKA ' .. bot.first_name ..' ('..bot.id..')')

	-- Generate a random seed and "pop" the first random number. :)
	math.randomseed(os.time())
	math.random()

	last_update = last_update or 0 -- Set loop variables: Update offset,
	last_cron = last_cron or os.time() -- the time of the last cron job,
	is_started = true -- whether the bot should be running or not.

end

on_msg_receive = function(msg) -- The fn run whenever a message is received.

	if msg.date < os.time() - 5 then return end -- Do not process old messages.
	if not msg.text then msg.text = msg.caption or '' end

	for i,v in ipairs(plugins) do
		for k,w in pairs(v.triggers) do
			if string.match(msg.text:lower(), w) then

				-- a few shortcuts
				msg.chat.id_str = tostring(msg.chat.id)
				msg.from.id_str = tostring(msg.from.id)
				msg.text_lower = msg.text:lower()

				local success, result = pcall(function()
					return v.action(msg)
				end)
				if not success then
					sendReply(msg, 'An unexpected error occurred.')
					print(msg.text, result)
					return
				end
				-- If the action returns a table, make that table msg.
				if type(result) == 'table' then
					msg = result
				-- If the action returns true, don't stop.
				elseif result ~= true then
					return
				end
			end
		end
	end

end

bot_init() -- Actually start the script. Run the bot_init function.

while is_started do -- Start a loop while the bot should be running.

	local res = getUpdates(last_update+1) -- Get the latest updates!
	if res then
		for i,v in ipairs(res.result) do -- Go through every new message.
			last_update = v.update_id
			on_msg_receive(v.message)
		end
	else
		print(config.errors.connection)
	end

	if last_cron < os.time() - 5 then -- Run cron jobs if the time has come.
		for i,v in ipairs(plugins) do
			if v.cron then -- Call each plugin's cron function, if it has one.
				local res, err = pcall(function() v.cron() end)
				if not res then print('ERROR: '..err) end
			end
		end
		last_cron = os.time() -- And finally, update the variable.
	end

end

print('Halted.')
