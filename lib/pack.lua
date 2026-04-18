
local function buildTree(infil,pack,depth,trail)
	if not depth then depth=0 end
	for _,n in pairs(fs.list(infil)) do
		local f=infil.."/"..n
		if fs.attributes(f).isDir then
			if trail then
				pack.write(trail.."/"..n)
				pack.write("\n")
				buildTree(f,pack,depth+1,trail.."/"..n)
			else
				pack.write(n)
				pack.write("\n")
				buildTree(f,pack,depth+1,n)
			end
		end
	end
end

local function buildDump(infil,pack,path)
	local list
	if path then
		list=fs.list(infil.."/"..path)
	else
		list=fs.list(infil)
	end
	for _,n in pairs(list) do
		local f				--file path relative to infile
		if path then 
			f=path.."/"..n
		else 
			f=n 
		end
		local fp=infil.."/"..f		--absolute file path
		local a=fs.attributes(fp)
		if a.isDir then
			buildDump(infil,pack,f)
		else
			pack.write(f)
			pack.write(">")
			pack.write(tostring(a.size))
			pack.write(">")
			local ff=fs.open(fp,'r')
			for ch=1,a.size do
				pack.write(ff.read(1))
			end
			ff.close()
		end
	end
end

function packup(infil,outfil)
	assert(fs.attributes(infil).isDir,"Input is not a directory")
	local pack=fs.open(outfil,'w')
	assert(pack,"Output path invalid")
	assert(pcall(buildTree,infil,pack),"Error building pack tree")
	pack.write("\n")
	assert(pcall(buildDump,infil,pack),"Error building pack dump")
	pack.close()
end

------------------------

local function parseTree(pack,outfil)
	repeat
		local out=pack.readLine()
		if out and out~="" then
			fs.makeDir(outfil.."/"..out)
		end
	until out==""
end

local function parseDump(pack,outfil)
	repeat
		local out=pack.read(1)
		local fil=""
		while out and out~=">" do
			fil=fil..out
			out=pack.read(1)
		end
		
		out=pack.read(1)
		local len=""
		while out and out~=">" do
			len=len..out
			out=pack.read(1)
		end
		len=tonumber(len)
		
		if type(len)=="number" then
			local ff=fs.open(outfil.."/"..fil,'w')
			for n=1,len do
				ff.write(pack.read(1))
			end
			ff.close()
		end
	until out==nil
end

function packdown(infil,outfil)
	assert(pcall(fs.makeDir,outfil),"Output path invalid")
	local pack=fs.open(infil,'r')
	assert(pack,"Pack file does not exist, or is inaccessable")
	
	assert(pcall(parseTree,pack,outfil),"Error parsing pack tree")
	assert(pcall(parseDump,pack,outfil),"Error parsing pack dump")
	
	pack.close()
end