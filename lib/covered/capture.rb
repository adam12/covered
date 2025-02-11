# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'wrapper'

require 'coverage'

module Covered
	class Capture < Wrapper
		def initialize(output)
			super(output)
			
			begin
				@trace = TracePoint.new(:line, :call, :c_call) do |trace|
					if trace.event == :call
						# Ruby doesn't always mark call-sites in sub-expressions, so we use this approach to compute a call site and mark it:
						if location = caller_locations(2, 1).first and path = location.path
							@output.mark(path, location.lineno, 1)
						end
					end
					
					if path = trace.path
						@output.mark(path, trace.lineno, 1)
					end
				end
			rescue
				warn "Line coverage disabled: #{$!}"
				@trace = nil
			end
		end
		
		def enable
			super
			
			@trace&.enable
		end
		
		def disable
			@trace&.disable
			
			super
		end
	end
	
	# class Capture < Wrapper
	# 	def enable
	# 		super
	# 
	# 		::Coverage.start
	# 	end
	# 
	# 	def disable
	# 		result = ::Coverage.result
	# 
	# 		puts result.inspect
	# 
	# 		result.each do |path, lines|
	# 			lines.each_with_index do |lineno, count|
	# 				@output.mark(path, lineno, count)
	# 			end
	# 		end
	# 
	# 		super
	# 	end
	# end
end
