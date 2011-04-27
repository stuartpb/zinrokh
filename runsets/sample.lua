--encoding: utf-8

--For getting the weather in London.
local http = require 'socket.http'

return {
  { name = "SEND SPIKE",
    run = function(self,report)
      report.summary "SPIKE SENT"
    end
  },
  { name = "Get weather in London",
    run = function(self,report)
      local wxml, err = http.request(
        "http://www.google.com/ig/api?weather=London")
      if not wxml then report.summary(err) end
      local curconds = string.match(wxml,
        "<current_conditions>(.-)</current_conditions>")
      if curconds then
        local cond = setmetatable({},
          {__index=function() return "???" end})
        local function get_data(field)
          cond[field] = string.match(curconds,
            string.format('<%s data="(.-)"/>',field))
        end
        get_data"condition"
        get_data"temp_f"

        report.summary(string.gsub(
          --176 = 0xB0 = ° in CP1252
          "<condition>, <temp_f> \176F",
          "<(.-)>",cond))
      else
        report.summary(wxml)
      end
    end
  },
}
