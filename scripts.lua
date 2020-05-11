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

function generate_index_name(tag, timestamp, record)
    returnval = -1
    seperator = "-"
    if record["type"] ~=nil and record["profileId"] ~=nil and record["_tag_projectName"] ~=nil then
        record["index_name"] = record["type"] .. seperator .. record["profileId"] .. seperator .. record["_tag_projectName"]
        returnval = 1
    elseif record["profileId"] ~=nil and record["cluster_name"] ~= nil and record["namespace_name"] == "kube-system" then
        record["index_name"] = "log" .. seperator .. record["profileId"] .. seperator .. record["cluster_name"]
        record["_plugin"] = "kube-cluster"
        record["_documentType"] = "cluster-logs"
        returnval = 1
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

function convert_resptime_s_to_ms_nginx(tag,timestamp,record)
    returnval = 0
    if record["upstream_response_time"] ~= nil and record["upstream_response_time"] ~= '' then
       record["upstream_response_time"] = record["upstream_response_time"] * 1000
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

function parse_agent_browser(tag, timestamp, record)
    returnval = 0
    if record["browserField1"] == nil or record["browserField1"] == "" then
        returnval = 1
        record["browser"] = record["agent"]
    elseif record["browserField3"] ~= nil and record["browserField3"] ~= "" then
        returnval = 1
        record["browser"] = record["browserField3"]
    elseif record["browserField1"] == "Chrome" then
        returnval = 1
        record["browser"] = record["browserField1"]
    else
        returnval = 1
        record["browser"] = record["browserField2"]
    end
    return returnval, timestamp, record
end

function add_geoip_info(tag, timestamp, record)
    if record["host"] == nil or record["host"] == "" then
        returnval = 0
    else
        returnval = 1
        cmd = io.popen("sh /etc/td-agent-bit/geoip/geoip.sh " .. record["host"])
        for line in cmd:lines() do
               size, metric = split(line)
               record[metric[1]] = metric[2]
        end
        cmd:close()
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
  if record["message"] then
    local buff = {}
    local str = record["message"]

    -- init positions
    local pos, end_pos = 1, str.len(str)

    local first_line = str:match("[^\n]+")
    pos = str.len(first_line) + 1
    first_line_msg = str:match("[^\\n]+")
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
    record["message"] = msg:gsub("\n"," ")
  end

  return record
end

function multiline_process(tag, timestamp, record)
  return 1, timestamp, merge_log(record)
end
