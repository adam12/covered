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

require_relative 'config'

require 'rspec/core/formatters'

$covered = Covered::Config.load

module Covered
	module RSpec
		class Formatter
			# The name `dump_summary` of this method is significant:
			::RSpec::Core::Formatters.register self, :dump_summary
			
			def initialize(output)
				@output = output
			end
			
			def dump_summary notification
				$covered.call(@output)
			end
		end
		
		module Policy
			def load_spec_files
				$covered.enable
				
				super
			end
			
			def covered
				$covered
			end
			
			def covered= policy
				$covered = policy
			end
		end
	end
end

if $covered.record?
	RSpec::Core::Configuration.prepend(Covered::RSpec::Policy)

	RSpec.configure do |config|
		config.add_formatter(Covered::RSpec::Formatter)
		
		config.after(:suite) do
			$covered.disable
		end
	end
end
