#!/usr/bin/lua5.3

-- script to fetch and parse latest-releases.yaml from master site
-- and fetch the latest minitootfs images for all available branches

local request = require("http.request")
local cqueues = require("cqueues")
local yaml = require("lyaml")
local lfs = require("lfs")

local mirror = "https://cz.alpinelinux.org/alpine"


function fetch(url)
	local headers, stream = assert(request.new_from_uri(url):go())
	local body= assert(stream:get_body_as_string())
	return headers:get(":status"), body
end

function errormsg(msg)
	io.stderr:write(string.format("Error: %s: %s\n", errmsg, url))
	return nil, msg
end

function fetch_file(url, outfile)
	local headers, stream = assert(request.new_from_uri(url):go())
	local partfile = string.format("%s.part", outfile)
	local f, errmsg = io.open(partfile, "w")
	if not f then
		return errormsg(errmsg)
	end
	local ok, errmsg, errnum = stream:save_body_to_file(f)
	f:close()
	if not ok then
		return errormsg(errmsg)
	end
	return os.rename(partfile, outfile)
end


function get_minirootfs(images, destdir)
	for _,img in pairs(images) do
		if img.flavor == "alpine-minirootfs" then
			if destdir then
				local url = string.format("%s/%s/releases/%s/%s",
					mirror, img.branch, img.arch, img.file)
				local archdir = string.format("%s/%s", destdir, img.arch)
				local ok, errmsg = lfs.mkdir(archdir)
				if not ok then
					return errormsg(errmsg)
				end
				fetch_file(url, string.format("%s/%s", archdir, img.file))
				print(img.file)
			end
			return { version=img.version, file=img.file, sha512=img.sha512 }
		end
	end
end


-- get array of minirootsfs releases --
function get_releases(branch, destdir)
	local arches = { "aarch64", "armhf", "armv7", "ppc64le" , "s390x", "x86", "x86_64" }
	local t = {}
	local loop = cqueues.new()
	for _, arch in pairs(arches) do
		loop:wrap(function()
			local url = string.format("%s/%s/releases/%s/latest-releases.yaml",
				mirror, branch, arch)
			local status, body = fetch(url)
			if status == "200" then
				t[arch] = get_minirootfs(yaml.load(body), destdir)
			end
		end)
	end
	loop:loop()
	return t
end

local branch = arg[1] or "edge"
local destdir = arg[2]

local f

if destdir then
	lfs.mkdir(destdir)
	f = io.open(string.format("%s/checksums.sha512", destdir), "w")
else
	f = io.stdout
end

for arch,rel in pairs(get_releases(branch, destdir)) do
	local line = string.format("%s  %s/%s\n", rel.sha512, arch, rel.file)
	f:write(line)
end

if f ~= io.stdout then
	f:close()
end

