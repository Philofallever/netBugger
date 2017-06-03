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
	return downt
end
--下载图片
local keyword="小林家的女仆龙"
local startpage =0
local endpage =20   --这儿是一个网页，每隔20一个新网页。。
--local dir = "F:/netbuger/"
local dir = "/Users/0280102pc0102/Desktop/whatitmeans/fig/"
if os.getenv("OS") == "Windows_NT" then 
	res,err= os.execute("mkdir ".. string.gsub(dir,"/","\\").. keyword)
else 
	res,err= os.execute("mkdir ".. dir .. keyword)
end
print("mkdir result:",res ,"error:",err)
for i,v in ipairs(dealurl(url,keyword,endpage)) do
	local pretime=socket.gettime()
	local ext = string.match(v,"%..+",-5)
	local file = io.open(dir .. keyword .. "/".. i ..ext,"wb")
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
