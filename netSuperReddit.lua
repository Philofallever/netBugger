--扒光某个贴吧所有的图片,改成如果有图片就立即序列化,因为发现贴吧有预料不到的情况,最后序列化的话可能走不到那一步--
local socket = require("socket")
local http = require("socket.http")
local reddit = {}
function  reddit:GetInst(REDDIT_NAME)
	self.redditaddr = "http://tieba.baidu.com/f?ie=utf-8&kw="
	self.redditname = REDDIT_NAME
	local context,err = http.request(self.redditaddr .. self.redditname)
	if err == 200 then 
		self.context = context 
		print("GET IN REDDIT [" .. REDDIT_NAME .. "] SUCCESS!")
	else
		print("GET IN REDDIT [" .. REDDIT_NAME .. "] FAILED,BECAUSE OF: " .. err)
		return 
	end
	self:InitAttr()
	--self:Serialize()
end

function reddit:InitAttr()				--初始化属性:endpn,reddits...
	self.pwd = string.sub(io.popen("pwd"):read("*a"),1,-2)
	self.dirdiv = package.config:sub(1,1)
	self.preaddr = "http://tieba.baidu.com/p/"
	self.listaddr = self.redditaddr .. self.redditname .. "&pn="
	self.reddits = {}
	if self.context ==nil then 
		return 
	end
	local reg_lastpn = "pn=(%d+)\"%s-class=\"%s-last%s-pagination%-item%s-\""
	self.curpn = 0
	self.intpn = 50 --每页间距
	local r_pos
	_,r_pos,self.endpn = string.find(self.context,reg_lastpn)
	if not self.endpn then 
		print("something goes wrong,can't get last page!")
		return
	end
	self.endpn  = self.endpn +0
	--@@@ 设置最多能爬取多少页，不然电脑就炸了
	self.endpn = math.min(self.endpn,50*100)
	if self.endpn == 50*100 then
		print("\27[37m贴吧帖子太多,将只爬取前100页内容\27[0m")
	end
	local reg_topic = "共有主题数.-(%d+).-贴子数.-(%d+)"
	_,r_pos,self.topicnum,self.redditnum  = string.find(self.context,reg_topic,r_pos)
	local reg_fan = ">(.-)</a>数.-(%d+)"
	_,r_pos,self.fanname,self.fannum = string.find(self.context,reg_fan,r_pos+20)
	local infomation = string.format("\n[%s]吧共有主题数[%s]个,帖子[%s]篇,会员[%s]:[%s]\n开始抽取帖子...\n",self.redditname,self.topicnum,self.redditnum,self.fanname,self.fannum)
	print(string.rep("*",string.len(infomation)) .. infomation .. string.rep("*",string.len(infomation)))
	self.picdir = self.pwd .. self.dirdiv .. "图片_" ..self.redditname
	local res,err = os.execute("mkdir " .. self.picdir)
	print("创建图片文件夹结果:",res,err)
	self:ListAll()
end

function reddit:Extract()				--抽取页面的帖子地址
	if self.context == nil then 
		return
	end
	local reg_topic = "<a href=\"/p/(%d+)\""
	for w in string.gmatch(self.context,reg_topic) do
		--if w == "3080630083" then 
		--	return
		--end
		table.insert(self.reddits,{addr = self.preaddr .. w})
	end
end

function reddit:ListAll()				--列出所有的页面,并抽取
	if self.curpn>self.endpn then 
	--if self.curpn > 10 then
		print("所有帖子已抽取完毕,开始解析...") 
		return self:PostDetail()
	end
	local context,err = http.request(self.listaddr .. self.curpn)
	if err ==200 then
		self.context = context
		print("LIST PAGE [" .. self.curpn .. "] of [" .. self.redditname .. "] SUCCESS!")
		self:Extract()
	else 
		self.context = nil 
		print("LIST PAGE [" .. self.curpn .. "] of [" .. self.redditname .."] FAILED,BECAUSE OF:" .. err)
		return
	end
	self.curpn = self.curpn +self.intpn
	return self:ListAll()
end

function reddit:PostDetail()									    --遍历治疗每个帖子 = =
	local listdetail = {}
	for k,reddit in pairs(self.reddits) do
		self.reddits[k].context = self:CreateCure(reddit.addr)
	end
end

function reddit:CreateCure(waddr,pn,pagecontext)					--治疗帖子成可阅读的= =
	local pn = pn or 1
	local pagecontext = pagecontext or {check_t = {}}
	local page_addr = waddr .."?pn=" .. pn
	local context,err = http.request(page_addr)
	if pn == 1 then 
		self.morestairs = false
		reg_stairsinfo = "PageData%.thread.-author:%s+\"(.+)\".-title:%s+\"(.+)\".-reply_num:(%d+)"
		--local author,title,reply_num
		pagecontext.info = {string.match(context,reg_stairsinfo)}
		local author,title,reply_num = table.unpack(pagecontext.info)
		local reg_morestairs = {"盖.+楼","真.+爱.+楼","天.+顶","来.+顶"}
		for i,v in ipairs(reg_morestairs) do
			if string.match(title,v) then
				self.morestairs = true
				break
			end
		end
		print(string.format("当前耗时:%0.3f		正在治疗帖子--> %s ... ",os.clock(),string.sub(pagecontext.info[2],1,30)))
	end
	if err ==200 then
		local reg_topic = "<cc>.-</cc>"
		local reg_stairsinfo = "PageData%.thread.-author: \"(.+)\" "
		for w in string.gmatch(context,reg_topic) do
			local cc = {id ="",all ="",img={},word={}}						--每一个帖子的内容
			local reg_id = "post_content_(%d+)"
			local id = string.match(w,reg_id)
			local reg_img = "BDE_Image\"%s-src=\"(http.-jpg)"				--匹配图片
			for img in string.gmatch(w,reg_img) do
				table.insert(cc.img,img)
			end
			local reg_header = "<.->"										--去掉所有的标头和空白
			cc.word,_ = string.gsub(w,reg_header,"")
			cc.word,_ = string.gsub(cc.word,"%s","")
			cc.all = w
			cc.id = id
			if pagecontext.check_t[id] then
				print(string.format("当前耗时:%2f 	当前帖子已治疗完毕:发现楼层数[%s]",os.clock(),#pagecontext))
				return pagecontext
			end
			--@@@@@盖楼的小朋友别闹,只爬取前5页,小小朋友跪了起的名字好奇怪,什么真爱楼天天顶没匹配到,卡住了.
			--@@@@@限制每个贴子最多只扒300楼
			if  #pagecontext>150 and  self.morestairs or #pagecontext >300 then 
				--self.morestairs and #pagecontext > 150 then 
				return pagecontext
			end
			pagecontext.check_t[id] = true
			--[[for i,stairs in ipairs(pagecontext) do 
				if stairs.id == id  then 
					return pagecontext
				end
			end]]
			table.insert(pagecontext,cc)
			if #cc.img~= 0 then
				local imgnum = #cc.img
				print(string.format("\27[37m在%s楼中发现%s张图片,开始下载...\27[0m",#pagecontext,imgnum))
				self:downimg(cc.img)
			end
		end

	else
		print("CREATE CURE [" .. waddr .. "] FAILED,BECAUSE OF:".. err)
	end
	return self:CreateCure(waddr,pn+1,pagecontext)	
end

function reddit:downimg(imglist)
	for i,imgurl in ipairs(imglist) do 
		local imgname = imgurl:match("(http.-)%.jpg")
		while (function() imgname = imgname:sub(imgname:find("/")+1) return imgname:find("/") end)() do
			--do nothing,just get name of this img from url
		end
		print("正在下载图片--> " .. imgname)
		local file = io.open(self.picdir .. self.dirdiv .. imgname .. ".jpg","w")
		local context,err = http.request(imgurl)
		if err == 200 then 
			file:write(context)
			file:close()
		else
			print("下载图片失败,错误码:",err)
			file:close()
		end	
	end
end

function reddit:Serialize()
	local file = io.open(self.pwd .. self.dirdiv ..self.redditname .. ".txt","w")
	local total_output = {}
	local total_imglist = {}
	for i,reddit in ipairs(self.reddits) do 
		--local output = string.format("作者:%30s标题:%s[%s回复]\n原贴地址:%s",table.unpack(reddit.info),reddit.addr)
		local ex_info = {table.unpack(reddit.context.info)}
		table.insert(ex_info,reddit.addr)
		local stair_output = {string.format("作者:%-30s标题:%s[%s回复]\n原贴地址:%s",table.unpack(ex_info))}
		for j,stair in ipairs(reddit.context) do
			table.insert(stair_output,string.format("%d楼:%s",j,stair.word))
			--if #stair.img>0 then 
			--	total_imglist[reddit.context.info[2]] = stair.img
			--end

		end
		table.insert(total_output,table.concat( stair_output,"\n"))
	end
	if file then 
		file:write(string.rep("*",30) .. "\n",table.concat(total_output, "\n".. string.rep("*",30) .. "\n"))
		file:close()
	end
	--[[接受图片
	res,err= os.execute("mkdir " .. self.pwd .. self.dirdiv.. "图片_" ..self.redditname)
	for title,imglist in pairs(total_imglist) do
		for i,imgaddr in ipairs(imglist) do
			local file = io.open(self.pwd ..self.dirdiv .."图片_" ..self.redditname .. self.dirdiv .. title .."_" ..  i .. ".jpg","wb")
			if file then
				local context,err = http.request(imgaddr)
				file:write(context)
				file:close()
			end
		end
	end]]
	local grat = [[
=========================================
=====[SERIALIZE COMPLETED,HAVE FUN!]=====
=========================================
]]
	print(grat)
end
--@@@@这儿改成正确的贴吧名字,不要写错了。
local REDDIT_NAME = "你的名字"
function reddit:Run(REDDIT_NAME)
	self:GetInst(REDDIT_NAME)
	--[[if false then
		package.path = package.path .. ";/Users/0280102pc0102/Desktop/whatitmeans/aul/?.lua"
		require("print_r")
		print_r(self.reddits)
	end
	if  #self.reddits ~= 0 then 
		self:Serialize()
	else
		print("NOTHING TO SERIALIZE,SIR")
	end]]
end
reddit:Run(REDDIT_NAME)
