JSON = require("JSON")
function toNumber_millisecond(tag, timestamp, record)
    record["time"] = tonumber(record["time"])
    return 1, timestamp, record
end

-- function generate_index_name(tag, timestamp, record)
--     returnval = -1
--     seperator = "-"
--     if record["type"] ~=nil and record["profileId"] ~=nil and record["_tag_projectName"] ~=nil then
--         record["index_name"] = record["type"] .. seperator .. record["profileId"] .. seperator .. record["_tag_projectName"]
--         returnval = 1
--     end
--     return returnval, timestamp, record
-- end

function haproxyParsing(tag, timestamp, record)
    returnval = 0
	if record["nonServer"] == nil then
		record["nonServer"] = "null"
		returnval = 1
	elseif record["backendServer"] == nil then
		record["backendServer"] = "null"
		returnval = 1
	end
    return returnval, timestamp, record
end

function mongod_transform(tag, timestamp, record)
    returnval = 0
    if record["level"] == "I" then
        record["level"] = "info"
        returnval = 1
    elseif record["level"] == "W" then
        record["level"] = "warning"
        returnval = 1
    elseif record["level"] == "E" then
        record["level"] = "error"
        returnval = 1
    elseif record["level"] == "F" then
        record["level"] = "fatal"
        returnval = 1
    elseif record["level"] == "D1" or record["level"] == "D2" or record["level"] == "D3" or record["level"] == "D4" or record["level"] == "D5" or record["level"] == "D" then
        record["level"] = "debug"
        returnval = 1

    end

    return returnval, timestamp, record
end

function convert_to_unique_lowercase(str)
    str=str:gsub("_","__")
    return (str:gsub("%u", function(c) return '_' .. c:lower() end))
end

function convertLevelCase(tag, timestamp, record)
    returnval = 0
    if record["level"] ~= nil then
        record["level"]= string.gsub(record["level"], "%s", "")
        record["level"]= string.lower(record["level"])
        returnval = 1
    end
    return returnval, timestamp, record
end

function kafka_zookeeper_record_transform(tag,timestamp, record)
    returnval = 0
    initial_char=":"
    if record["level"] == "warn" then
        record["level"] = "warning"
        returnval = 1
    end
    if record["process_id"] ~= nil then
        opSplit = {}
        i = 0
        for token in string.gmatch(record["process_id"], '([^=]+)') do
                opSplit[i] = token
                 i = i +1
        end
        if opSplit[1] == nil then
            record["process_id"] = opSplit[0]
            return 1, timestamp, record
        end
        j = 0
        for token in string.gmatch(opSplit[1], '([^ ]+)') do
                opSplit[j] = token
                 j = j +1
        end
        record["process_id"] = opSplit[0]
        returnval = 1
    end
    if record["message"] ~= nil and record["message"]:sub(1, #initial_char) == initial_char then
        record["message"] = string.sub(record["message"], 2)
        returnval = 1
    end
    return returnval,timestamp, record
end

function generate_index_name(tag, timestamp, record)
    returnval = -1
    seperator = "-"
    if record["type"] ~=nil and record["profileId"] ~=nil and record["_tag_projectName"] ~=nil then
        record["index_name"] = record["type"] .. seperator .. record["profileId"] .. seperator .. convert_to_unique_lowercase(record["_tag_projectName"])
        returnval = 1
    elseif record["profileId"] ~=nil and record["cluster_name"] ~= nil and record["_plugin"] == "kube-cluster" then
        record["index_name"] = "log" .. seperator .. record["profileId"] .. seperator .. convert_to_unique_lowercase(record["cluster_name"])
        returnval = 1
    end
    return returnval, timestamp, record
end

function klog_level_transform(tag, timestamp, record)
    if record["level"] == "I" then
        record["level"] = "info"
    elseif record["level"] == "W" then
        record["level"] = "warn"
    elseif record["level"] == "E" then
        record["level"] = "error"
    elseif record["level"] == "F" then
        record["level"] = "fatal"
    else
        record["level"] = "info"
    end
    return 1, timestamp, record
end

function addtime_millisecond(tag, timestamp, record)
    record["time"] = math.floor((timestamp)*1000)
    return 1, timestamp, record
end


function syslog_transform(tag, timestamp, record)
    if record["level"] == nil or record["level"] == '' then
        record["level"] = "info"
    else
        record["level"] = record["level"]:gsub("%s+", "")
    end
    return 1, timestamp, record
end

function syslog_parsing(tag, timestamp, record)
    returnval = -1
    if record["message"] == nil or record["message"] == '' then
        returnval = -1
    else
        returnval = 1
        loglevel = string.match(record["message"], '%[%s*%a+%s*%]')
        if loglevel~= nil then
            record["level"] = string.match(loglevel, '%a+')
        end
    end
    return returnval, timestamp, record
end

function postgres_general_transform(tag, timestamp, record)
    if record["level"] ~= nil then
        record["level"] = string.lower(record["level"])
        return 1, timestamp, record
    end
end

function mysql_error_transform(tag, timestamp, record)
    if record["level"] == nil or record["level"] == '' then
	record["level"] = "info"
        returnval = 1
    end
    record["level"] = string.lower(record["level"])
    return 1, timestamp, record
end


function apache_record_transform(tag,timestamp, record)
    opSplit = {}
    i = 0
    returnval = 0
    if record["level"] ~= nil then
    for token in string.gmatch(record["level"], '([^:]+)') do
        opSplit[i] = token
        i = i +1
    end
    if  opSplit[1] ~= nil then
        record["level"] = opSplit[1]
        if record["level"] == "warn" then
           record["level"] = "warning"
        end
        returnval = 1
    end
    end
    opSplit = {}
    i = 0
    if record["id"] ~= nil then
    for token in string.gmatch(record["id"], '([^: ]+)') do
        opSplit[i] = token
        i = i +1
    end
    record["id"] = nil
    record["pid"] = opSplit[0]
    record["tid"] = opSplit[2]
    returnval = 1
    end
    return returnval,timestamp, record
end

function convert_resptime_us_to_ms_apache(tag,timestamp,record)
    returnval = 0
    if record["response_time"] ~= nil and record["response_time"] ~= '' then
       record["response_time"] = record["response_time"] / 1000
       returnval = 1
    end
    return returnval, timestamp, record
end

function addtimeGMToffset_millisecond(tag, timestamp, record)
    utcNow = os.time()
    offset = os.difftime(utcNow, os.time(os.date("!*t")))
    if os.date('*t')['isdst'] then
        offset = offset + 3600
    end
    record["time"] = math.floor((timestamp-offset)*1000)
    return 1, timestamp, record
end

function convert_req_resp_time_s_to_ms_nginx(tag,timestamp,record)
    returnval = 0
    if record["upstream_response_time"] ~= nil and record["upstream_response_time"] ~= '' then
       record["upstream_response_time"] = record["upstream_response_time"] * 1000
       returnval = 1
    end
    if record["upstream_header_time"] ~= nil and record["upstream_header_time"] ~= '' then
       record["upstream_header_time"] = record["upstream_header_time"] * 1000
       returnval = 1
    end
    if record["upstream_connect_time"] ~= nil and record["upstream_connect_time"] ~= '' then
       record["upstream_connect_time"] = record["upstream_connect_time"] * 1000
       returnval = 1
    end
    if record["request_time"] ~= nil and record["request_time"] ~= '' then
       record["request_time"] = record["request_time"] * 1000
       returnval = 1
    end
    return returnval, timestamp, record
end

function cb_drop(tag, timestamp, record)
   if record["log"] == nil then
        returnval = 1
   else
        returnval = -1
   end
   return returnval, timestamp, record
end

function user_drop(tag, timestamp, record)
    returnval = 0
    if record["drop"] ~= nil then
            returnval = -1
    end
    return returnval, timestamp, record
end

function parse_url_path_query(tag, timestamp, record)
    if record["path"] == nil or record["path"] == '' then
        returnval = 0
    elseif record["path"] == "/" then
        returnval = 1
    else
        returnval = 1
        tmp = {}
        i = 0
        for field in record["path"]:gmatch("[^?]+") do
            tmp[i] = field
            i = i + 1
        end
        j = 0
        pathstring = ""
        while j < i-1 do
            pathstring = pathstring .. tmp[j]
            j = j+1
        end
        if pathstring ~= nil and pathstring ~= "" then
            record["path"] = pathstring
        end
    end
    return returnval, timestamp, record
end

function parse_url_path_id(tag, timestamp, record)
    if record["path"] == nil or record["path"] == '' then
        returnval = 0
    elseif record["path"] == "/" then
        returnval = 1
    else
        returnval = 1
        local tmp = ""
        for field in record["path"]:gmatch("[^/]+") do
            if tonumber(field) then
                tmp = tmp .. "/[id]"
            else
                tmp = tmp .. "/" .. field
            end
        end
        record["path"] = tmp
    end
    return returnval, timestamp, record
end

function agent_fields_cleanup(record)
    if record["platform"] ~= nil then
        record["platform"] = nil
    end
    if record["engine"] ~= nil then
        record["engine"] = nil
    end
    if record["system"] ~= nil then
        record["system"] = nil
    end
    if record["kit"] ~= nil then
        record["kit"] = nil
    end
    if record["fields"] ~= nil then
        record["fields"] = nil
    end
    if record["field1"] ~= nil then
        record["field1"] = nil
    end
    if record["field2"] ~= nil then
        record["field2"] = nil
    end
    if record["field3"] ~= nil then
        record["field3"] = nil
    end
    if record["field4"] ~= nil then
        record["field4"] = nil
    end
end

function check_mobile(record)
    if record["fields"] ~= nil then
        if string.find(string.lower(record["fields"]),"mobile") then
            return true
        end
    end 
    return false
end

function parse_agent_browser(tag, timestamp, record)
    record["browser"] = "Others"
    if record["fields"] ~= nil and (string.find(record["fields"],"Edge") or string.find(record["fields"],"Edge")) then
        record["browser"] = "Edge"
    elseif  record["fields"] ~= nil and string.find(record["fields"],"Chromium") then
        record["browser"] = "Chromium"
    elseif  record["fields"] ~= nil and string.find(record["fields"],"Focus") then
        record["browser"] = "Firefox Focus"
    elseif  record["fields"] ~= nil and string.find(record["fields"],"UCBrowser") then
        record["browser"] = "UC Browser"
    elseif  record["fields"] ~= nil and string.find(record["fields"],"BingWeb") then
        record["browser"] = "Bing"
    elseif  record["fields"] ~= nil and string.find(record["fields"],"Dolfin") then
        record["browser"] = "Dolfin"
    elseif  record["fields"] ~= nil and string.find(record["fields"],"MiuiBrowser") then
        record["browser"] = "Miui Browser"
    elseif  record["fields"] ~= nil and string.find(record["fields"],"VivoBrowser") then
        record["browser"] = "Vivo Browser"
    elseif  record["fields"] ~= nil and string.find(record["fields"],"Instagram") then
        record["browser"] = "Instagram"
    elseif  record["fields"] ~= nil and string.find(record["fields"],"Hawk") then
        record["browser"] = "Hawk"
    elseif record["fields"] ~= nil and string.find(record["fields"],"Firefox") then
        record["browser"] = "Firefox"
    elseif record["field1"] == nil and record["system"] ~= nil and string.find(record["system"],"MSIE") then
        record["browser"] = "Internet Explorer"
    -- Opera mini --
    elseif record["system"] ~= nil and string.find(record["system"],"Opera Mini") then
        record["browser"] = "Opera Mini"
    -- Opera check --
    elseif (record["fields"] ~= nil and string.find(record["fields"],"OPR")) or (record["engine"] ~= nil and string.find(record["engine"],"Opera")) then
        record["browser"] = "Opera"
    -- Safari Check --
    elseif (record["fields"] ~= nil and record["field1"] == "Version" and (record["field2"] == "Safari" or record["field3"] == "Safari") and string.find(record["fields"],"Chrome") == nil) or (record["fields"] ~= nil and record["field1"] == "Safari" and string.find(record["fields"],"Chrome") == nil) then
        record["browser"] = "Safari"
    -- Chrome check --
    elseif (record["fields"] ~= nil and record["field1"] == "Version" and record["field2"] == "Chrome" and record["field3"] == "Safari" and record["field4"] == nil) or (record["fields"] ~= nil and record["field1"] == "Chrome" and record["field2"] == "Safari" and record["field3"] == nil ) then
        record["browser"] = "Chrome"
    elseif record["agent"] ~= nil and string.find(string.lower(record["agent"]),"http") and string.find(string.lower(record["agent"]),"client") then
        record["browser"] = "Http Client"
    end

    if check_mobile(record) and record["browser"] ~= "Others" then
        record["browser"] = record["browser"] .. " " .. "Mobile"
        record["mobile"] = "Yes"
    end
    agent_fields_cleanup(record)
    returnval = 1
    if record["log"] ~= nil then
        returnval = 0
    end
    return returnval, timestamp, record
end

function checkGeoTags(tag, timestamp, record)
    returnval = 0
    if record["country_name"] == nil or record["country_name"] == '' then
        record["country_name"] = "-Unknown-"
        returnval = 1
    end
    if record["city"] == nil or record["city"] == '' then
            record["city"] = "-Unknown-"
            returnval = 1
    end
    if record["region_code"] == nil or record["region_code"] == '' then
            record["region_code"] = "-Unknown-"
            returnval = 1
    end
    if record["region_name"] == nil or record["region_name"] == '' then
            record["region_name"] = "-Unknown-"
            returnval = 1
    end
    if record["country"] == nil or record["country"] == '' then
            record["country"] = "-Unknown-"
            returnval = 1
    end
    if record["longitude"] == nil or record["longitude"] == '' then
            record["longitude"] = "-Unknown-"
            returnval = 1
    end
    if record["latitude"] == nil or record["latitude"] == '' then
            record["latitude"] = "-Unknown-"
            returnval = 1
    end

    return returnval, timestamp, record
end

function split(string_to_split)
    local words = {}
    count = 0
    for w in (string_to_split .. ":"):gmatch("([^:]*):") do
        table.insert(words, w)
        count = count + 1
    end
    return count,words
end

local function merge_log(record)
  if record["multiline_message"] then
    local buff = {}
    local str = record["multiline_message"]

    -- init positions
    local pos, end_pos = 1, str.len(str)

    local first_line = str:match("[^\n]+")
    pos = str.len(first_line) + 1
    first_line_msg = first_line:match("(.*)\\n")
    -- record["time"] = first_line:match("\"time\":\"([^/]+)\"")
    table.insert(buff,first_line_msg)

    -- trying to recursively JSON parse the rest of the string to extract the value of 'log'
    while(pos < end_pos)
    do
      local success, value, next_i = pcall(JSON.grok_one, JSON, str, pos, {})
      if success then
        table.insert(buff, value["log"])
        pos = next_i
      else
        -- if we can't parse as JSON, just append the rest of the line into the buffer
        table.insert(buff, string.sub(str, pos))
        break
      end
    end

    msg = table.concat(buff, "")
    -- Removing \n character
    msg = msg:gsub("\n"," ")
    record["multiline_message"] = msg:gsub("\t","")
  end

  return record
end

function multiline_process(tag, timestamp, record)
  return 1, timestamp, merge_log(record)
end



