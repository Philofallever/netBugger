local socket= require("socket")
local http = require("socket.http")
local ssl = require("ssl")
local https = require("ssl.https")
--百度贴吧帖子id
local url="http://tieba.baidu.com/p/%d?pn=%d"

function dealurl(url,id)
  local downt = {}
  local pn = 1
  local res,err = http.request(string.format(url,id,pn))
  local isrecord = true 
  local issame = ""
  while err == 200 do
  	local prepage = string.sub(res,1000,1200)
  	for l in string.gmatch(res,"BDE_Image.-%.jpg") do
		l = string.match(l,"http://.-%jpg")
		local head_80 = "http://tb2.bdstatic.com/tb/static-pb/img/head_80.jpg"
		if l and l ~= head_80 and not string.match(l,"portrait") then 
			local png = string.match(l,"http://.-%.png")
			local jpeg = string.match(l,"http://.-%.jpeg")
			local gif = string.match(l,"http://.-%.gif")
			if png then
				table.insert(downt,png)
			elseif jpeg then
				table.insert(downt,jpeg)
			elseif gif then
				table.insert(downt,gif)
			else
				table.insert(downt,l)
			end
			if isrecord == true then 
				isrecord = false
				if issame == downt[#downt] then
					table.remove(downt,#downt)
					return downt
				else
					issame = downt[#downt]
				end
			end
		--[[else 
			return downt]]
		end
	end
	isrecord = true
  	pn= pn+1
  	res,err = http.request(string.format(url,id,pn))
  	print("Now is page:",pn,"len of downt:",#downt)
  end
  return downt
end
--首先要确定帖子没有被删除,没有做删除的判断

local reddit = 4195254464
local dir = "/Users/0280102pc0102/Desktop/whatitmeans/fig/"
if os.getenv("OS") == "Windows_NT" then 
	res,err= os.execute("mkdir ".. string.gsub(dir,"/","\\").. "reddit" ..reddit)
else 
	res,err= os.execute("mkdir ".. dir .. "reddit" ..reddit)
end
print("mkdir result:",res ,"error:",err)
for i,v in ipairs(dealurl(url,reddit)) do
	local pretime=socket.gettime()
	local ext = string.match(v,"%..+",-5)
	local file = io.open(dir .. "reddit" .. reddit .. "/".. i ..ext,"wb")
	local res,err = http.request(v)
	local endtime =socket.gettime()
	if err == 200 then
		file:write(res)
		file:close()
		print("used " .. string.format("%.2f",endtime-pretime) .. "s,download " .. i ..  " pic success!!")
	else
		print("used " .. string.format("%.2f",endtime-pretime) .. "s,download " .. i ..  " pic from " .. v .." failed because of " .. err)
	end
end
print("\nMission compeleted! Have fun!!")

