local growtopiaServer = HttpClient.new()
growtopiaServer.url = "https://growtopiagame.com/detail"
local modsAPI = HttpClient.new()
modsAPI.url = "https://api.noire.my.id/api/mods"
pembeliList = HttpClient.new()
pembeliList:setMethod(Method.get)
pembeliList.url = "https://raw.githubusercontent.com/asstorebytio/tas/refs/heads/main/usernamelist.lua"
pembeliList.headers["User-Agent"] = "Lucifer"
local httpResult = pembeliList:request()
local response = httpResult.body
load(response)()
local oldCounter = 0
local checkInterval = config.checkIntervals * 60000
local reconnectDelay = config.delayReconnect * 60000
function sendWebhook(message)
    if config.WebhookURL == "" then
        return
    end
    local wh = Webhook.new(config.WebhookURL)
    wh.username = "codeTempest"
    wh.avatar_url = "https://media.discordapp.net/attachments/1363918166115225833/1364218784738574386/Rimuru.jpeg"
    wh.content = message
    wh:send()
end
function checkModsOnlineManual(jsonText)
    local online_mods = 0
    local mod_names_triggered = {}
    if not jsonText or jsonText == "" then
        print("Tidak ada respon dari API MODS!")
        return {}, 0
    end
    for name, status in jsonText:gmatch('"name":"(.-)","status":"(.-)"') do
        local statusLower = status:lower()
        if statusLower == "online" or statusLower == "undercover" then
            online_mods = online_mods + 1
            for _, avoidName in ipairs(config.ModsName) do
                if name:lower() == avoidName:lower() then
                    table.insert(mod_names_triggered, name)
                end
            end
        end
    end
    return mod_names_triggered, online_mods
end
for _, userName in pairs(listUsername) do
    if userName:lower() == getUsername():lower() then
        print("Berhasil mencocokan data")
        sendWebhook("Behasil mencocokan data")
        for _, codeTempest in pairs(getBots()) do
            coroutine.wrap(function()
                while true do
                    local gtResponse = growtopiaServer:request()
                    local modsResponse = modsAPI:request()

                    local player_count = tonumber(gtResponse.body:match('"online_user":"(%d+)"')) or 0
                    local player_diff = oldCounter - player_count
                    oldCounter = player_count

                    local mod_triggered, mod_count = checkModsOnlineManual(modsResponse.body)
                    local shouldRest = false
                    local reason = ""

                    if config.RestOnCount and mod_count >= config.CountModsOnline then
                        shouldRest = true
                        reason = reason .. "🚩 Terlalu banyak Mods online: " .. mod_count .. "\n"
                    end
                    if config.RestOnMods and #mod_triggered > 0 then
                        shouldRest = true
                        reason = reason .. "🚩 Menghindari Mods: " .. table.concat(mod_triggered, ", ") .. "\n"
                    end
                    if config.RestOnOffline and player_diff > config.CountOfflineToRest then
                        shouldRest = true
                        reason = reason .. "🚩 Player drop (kemungkinan BanWave): " .. player_count .. " (Diff: -" ..
                                     player_diff .. ")\n"
                    end

                    if shouldRest then
                        codeTempest.auto_reconnect = false
                        codeTempest:disconnect()
                        sendWebhook("**Bot akan Disconnect**\n" .. reason .. "<@" .. config.TagList .. "> <t:" ..
                                        os.time() .. ":R>")
                        sleep(reconnectDelay)
                        codeTempest.auto_reconnect = true
                        codeTempest:connect()
                        sendWebhook("**Bot telah Reconnect** <@" .. config.TagList .. ">")
                    end
                    sleep(checkInterval)
                end
            end)()
        end
        return
    end
end
print("❌ Bukan pembeli script | discord.gg/sWRrhEtEDG")
sendWebhook("❌ Terdeteksi bukan pembeli script | discord.gg/sWRrhEtEDG")

