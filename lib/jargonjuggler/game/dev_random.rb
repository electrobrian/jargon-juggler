#!/usr/local/bin/ruby
# Copyright (c) 2000 Brian Fundakowski Feldman
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $Id: devrandom.rb,v 1.4 2000/10/09 06:50:44 green Exp $

# This is a class to get higher quality random data than normal.
# It requires a /dev/urandom or /dev/random, but maybe it should
# support some other ways, too.
class DevRandom
	def initialize
		begin
			@dev = open '/dev/urandom', 'r'
		rescue
			@dev = open '/dev/random', 'r'
		end
	end
	def DevRandom.read(bytes)
		return DevRandom.new.read bytes
	end
	def read(bytes)
		b = 0
		@dev.read(bytes).unpack('C' * bytes).each {|n| b = b << 8 | n}
		return b
	end
end

if __FILE__ == $0
	puts "Testing DevRandom.new: " + begin
		blah = DevRandom.new
	rescue
		$!
	else
		"success"
	end
end

