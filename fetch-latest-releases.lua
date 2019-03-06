#!/usr/bin/lua5.3

-- script to fetch and parse latest-releases.yaml from master site
-- and fetch the latest minitootfs images for all available branches

local request = require("http.request")
local cqueues = require("cqueues")
local yaml = require("lyaml")
local lfs = require("lfs")

local mirror = os.getenv("MIRROR") or "https://cz.alpinelinux.org/alpine"

function fatal(...)
	errormsg(...)
	os.exit(1)
end

function fetch(url)
	local headers, stream = request.new_from_uri(url):go()
	if not headers then
		fatal("Error: %s: %s", url, stream)
	end
	local body = stream:get_body_as_string()
	return headers:get(":status"), body
end

function errormsg(...)
	local msg = string.format(...)
	io.stderr:write(string.format("%s\n", msg))
	return nil, msg
end

function fetch_file(url, outfile)
	local headers, stream = request.new_from_uri(url):go()
	if not headers then
		fatal("Error: %s: %s", url, stream)
	end
	if headers:get(":status") ~= "200" then
		fatal("Error: HTTP %s: %s", headers:get(":status"), url)
	end

	local partfile = string.format("%s.part", outfile)
	local f, errmsg = io.open(partfile, "w")
	if not f then
		return errormsg("Error: %s: %s:", file, errmsg)
	end
	local ok, errmsg, errnum = stream:save_body_to_file(f)
	f:close()
	if not ok then
		return errormsg("Error: %s: %s", errmsg, url)
	end
	return os.rename(partfile, outfile)
end

function mkdockerfile(dir, rootfsfile)
	local filename = string.format("%s/Dockerfile", dir)
	local f, err = io.open(filename, "w")
	if not f then
		fatal("Error: %s: %s", filename, err)
	end
	f:write(string.format("FROM scratch\nADD %s /\nCMD [\"/bin/sh\"]\n", rootfsfile))
	f:close()
end

function get_minirootfs(images, destdir)
	for _,img in pairs(images) do
		if img.flavor == "alpine-minirootfs" then
			if destdir then
				local url = string.format("%s/%s/releases/%s/%s",
					mirror, img.branch, img.arch, img.file)
				local archdir = string.format("%s/%s", destdir, img.arch)
				local ok, errmsg = lfs.mkdir(archdir)
				fetch_file(url, string.format("%s/%s", archdir, img.file))
				mkdockerfile(archdir, img.file)
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
				t[arch] = get_minirootfs((yaml.load(body)), destdir)
			end
		end)
	end
	loop:loop()
	return t
end

local branch = arg[1] or "edge"
local destdir = arg[2] or "out"

lfs.mkdir(destdir)

local version
local releases = get_releases(branch, destdir)

if next(releases) == nil then
	fatal("No releases found on %s/%s/releases", mirror, branch)
end

local f = io.open(string.format("%s/checksums.sha512", destdir), "w")
for arch,rel in pairs(releases) do
	local line = string.format("%s  %s/%s\n", rel.sha512, arch, rel.file)
	f:write(line)
	version=rel.version
end
f:close()

-- write version
f = io.open(string.format("%s/VERSION", destdir), "w")
f:write(version)
f:close()

