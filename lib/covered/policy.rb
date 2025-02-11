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

require_relative "summary"
require_relative "files"
require_relative "source"
require_relative "capture"
require_relative "cache"
require_relative "persist"

module Covered
	class Policy < Wrapper
		def initialize
			super(Files.new)
			
			@reports = []
		end
		
		attr :output
		
		def freeze
			return self if frozen?
			
			capture
			@reports.freeze
			
			super
		end
		
		def source(*args)
			@output = Source.new(@output, *args)
		end
		
		def include(*args)
			@output = Include.new(@output, *args)
		end
		
		def skip(*args)
			@output = Skip.new(@output, *args)
		end
		
		def only(*args)
			@output = Only.new(@output, *args)
		end
		
		def root(*args)
			@output = Root.new(@output, *args)
		end
		
		def cache!
			@output = Cache.new(@output)
		end
		
		def persist!
			@output = Persist.new(@output)
		end
		
		def capture
			@capture ||= Capture.new(@output)
		end
		
		def enable
			capture.enable
		end
		
		def disable
			capture.disable
		end
		
		def flush
			@output.flush
		end
		
		attr :reports
		
		class Autoload
			def initialize(name)
				@name = name
			end
			
			def new
				begin
					klass = Covered.const_get(@name)
				rescue NameError
					require_relative(snake_case(@name))
				end
				
				klass = Covered.const_get(@name)
				
				return klass.new
			end
			
			def call(*args)
				self.new.call(*args)
			end
			
			def to_s
				"\#<#{self.class} loading #{@name}>"
			end
			
			private
			
			def snake_case(name)
				name.gsub(/(.+)(?=[A-Z\z])/){$1 + '_'}.downcase
			end
		end
		
		def reports!(coverage)
			if coverage.is_a?(String)
				names = coverage.split(',')
				
				names.each do |name|
					begin
						klass = Covered.const_get(name)
						@reports << klass.new
					rescue NameError
						@reports << Autoload.new(name)
					end
				end
			elsif coverage
				@reports << Covered::BriefSummary.new
			end
		end
		
		def call(*args)
			@reports.each do |report|
				report.call(self, *args)
			end
		end
	end
end
