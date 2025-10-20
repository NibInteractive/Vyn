-- Binary Testing
local Binary = {}

-- Number to Binary
function Binary.ToBinary(Number)
	if type(Number) ~= "number" then
		error("Expected number, got " .. type(Number))
	end

	local Bits = {}

	repeat
		table.insert(Bits, 1, Number % 2)
		Number = math.floor(Number / 2)
	until Number == 0

	return table.concat(Bits)
end

-- Binary to Number
function Binary.toDecimal(Bin)
	if type(Bin) ~= "string" then
		error("Expected string, got " .. type(Bin))
	end

	local Number = 0

	for i = 1, #Bin do
		local Bit = tonumber(Bin:sub(i, i))

		if Bit ~= 0 and Bit ~= 1 then
			error("Invalid binary digit at position " .. i)
		end

		Number = Number * 2 + Bit
	end

	return Number
end

-- UTF-8 String to Binary
function Binary.stringToBinary(str)
	local Result = {}
	for p, c in utf8.codes(str) do
		local codepoint = c
		local Bin = Binary.ToBinary(codepoint)

		-- pad to 16 Bits (or more if needed)
		local Size = math.max(8, math.ceil(math.log(codepoint + 1, 2)))
		Bin = string.rep("0", Size - #Bin) .. Bin
		table.insert(Result, Bin)
	end

	return table.concat(Result, " ")
end

-- Binary to UTF-8 String
function Binary.binaryToString(BinaryString)
	local Result = {}

	for ByteString in BinaryString:gmatch("%S+") do
		local Number = Binary.toDecimal(ByteString)
		table.insert(Result, utf8.char(Number))
	end

	return table.concat(Result)
end

print("Number to Binary:", Binary.ToBinary(42))                   --> 101010
print("Binary to Number:", Binary.toDecimal("101010"))             --> 42
print("String to Binary:", Binary.stringToBinary("Hi 😊"))         --> 01001000 01101001 11110000 10011111 10011001 10001010
print("Binary to String:", Binary.binaryToString("01001000 01101001 11110000 10011111 10011001 10001010")) --> Hi 😊

return Binary
