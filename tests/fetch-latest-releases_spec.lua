describe("test fetch-latest-releases functions", function()
	local f

	local function fetch(url)
		data = {}
		data["/v3.13/releases/aarch64/latest-releases.yaml"] = [[---
-
  title: "Mini root filesystem"
  branch: v3.13
  arch: aarch64
  version: 3.13.4
  flavor: alpine-minirootfs
  file: alpine-minirootfs-3.13.4-aarch64.tar.gz
  iso: alpine-minirootfs-3.13.4-aarch64.tar.gz
  date: 2021-04-14
  time: 10:28:29
  size: 2620916
  sha256: 5b359d72aa693d38945c0eb22a0f7a8071071af1914d04f59267230c9a2fe2b5
  sha512: 32d8832b81848566a5aecfbb21ea507e439bca123b611e586d27b02cadb94e5169e82e56f76c12c32d037aa4c0e8bec9bc4d98e5dd321d94876807d09e4c7f9c
]]
		data["/v3.13/releases/x86/latest-releases.yaml"] = [[---
-
  title: "Mini root filesystem"
  branch: v3.13
  arch: x86
  version: 3.13.5
  flavor: alpine-minirootfs
  file: alpine-minirootfs-3.13.5-x86.tar.gz
  iso: alpine-minirootfs-3.13.5-x86.tar.gz
  date: 2021-04-14
  time: 10:25:51
  size: 2742455
  sha256: 7144c4b209ba7cf2e7c29eefefd1194a1150b5f34b6854104cf4a3d20b7e3053
  sha512: 843077403fc3ea031c8c4e2907d707b235890cc6ba7ea6489894ba5559cff04d988b3bad0cdbddfc4ebd5a54fed42a582823ea3f8b4bc2d22cf49c97aca9f70f
-
  title: "Virtual"
  branch: v3.13
  arch: x86
  version: 3.13.5
  flavor: alpine-virt
  file: alpine-virt-3.13.5-x86.iso
  iso: alpine-virt-3.13.5-x86.iso
  date: 2021-04-14
  time: 10:30:25
  size: 38797312
  sha256: cf7ca3ae1459a2b8e973decd74ae939e70d09e14fdeb8edc6c064d7d27e4ea83
  sha512: 034954ae76d920067f56fc9275512d9b611887f9806a90040cd85ba6346a4503a9afa16ef8f6a2f950b637371be06ca5a280a6f7632f9d2ba658ea69746afd18
]]
		if data[url] then
			return "200", data[url]
		end
		return "404", ""
	end

	setup(function()
		f = require("fetch-latest-releases")
		f.fetch = fetch
		f.mirror = ""
	end)

	teardown(function()
		f = nil
	end)

	describe("test fatal", function()
		it("should call os.exit", function()
			stub(os, "exit")
			f.fatal("hello")
			assert.stub(os.exit).was_called_with(1)
		end)
	end)

	describe("test minirootfs_image", function()
		it("should return flavor=alpine-minirootfs", function()
			local img = f.minirootfs_image({ { flavor="alpine-rpi"}, { flavor="alpine-minirootfs"}})
			assert.are.same({flavor="alpine-minirootfs"}, img)
		end)
	end)

	describe("test get_minirootfs", function()
		it("should call fetch_file", function()
			res = f.get_minirootfs({
				{ flavor="alpine-rpi", version="3.13.5"},
				{ flavor="alpine-minirootfs", version="3.13.5"},
			})
			assert.are.same("3.13.5", res.version)
		end)
	end)

	describe("test get_releases", function()
		it("should return 3.13.4 for aarch64", function()
			rels = f.get_releases("v3.13")
			assert.are.same("3.13.4", rels.aarch64.version)
		end)
		it("should return 3.13.5 for x86", function()
			rels = f.get_releases("v3.13")
			assert.are.same("3.13.5", rels.x86.version)
		end)
	end)

	describe("test equal_versions", function()
		it("should return false", function()
			ret = f.equal_versions(f.get_releases("v3.13"))
			assert.is_falsy(ret)
		end)
	end)
end)
