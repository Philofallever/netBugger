local socket= require("socket")
local http = require("socket.http")
--百度搜索链接
local url="http://image.baidu.com/search/flip?tn=baiduimage&ie=utf-8&word=%s&pn=%d"
--"objURL":"http://cdn.duitang.com/uploads/item/201411/07/20141107183020_T3uRz.jpeg",
function dealurl(url,keyword,startpage,endpage)
 	--如果只传入3个参数则，设置startpage为20，endpage为传入的值
 	if endpage == nil then
 		endpage = startpage
 		startpage=0
 	end
	local downt={}
	for i = startpage,endpage,20 do
		pageurl = string.format(url,keyword,i)
		print("Deal with pageurl: ".. pageurl)
		local res,err= http.request(pageurl)
		if  err == 200 then
			for l in string.gmatch(res,"objURL\34:\34http://.-%.jpg") do
				if not string.find(l,"\n") then	
					l = string.sub(l,10)
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
				end
			end
		end
	end
	return downt
end
--下载图片
local keyword="吹响吧!上低音号"
local startpage =0
local endpage =100   --这儿是一个网页，每隔20一个新网页。。
links = dealurl(url,keyword,endpage)

for i,v in ipairs(links) do
	print(v)
end