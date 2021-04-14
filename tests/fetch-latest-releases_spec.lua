describe("test fetch-latest-releases functions", function()
	local f
	setup(function()
		f = require("fetch-latest-releases")
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
end)
