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

require 'msgpack'
require 'time'
require 'set'
require 'console'

module Covered
	class Persist < Wrapper
		DEFAULT_PATH = ".covered.db"
		
		def initialize(output, path = DEFAULT_PATH)
			super(output)
			
			@path = path
			@touched = Set.new
		end
		
		def apply(record, ignore_mtime: false)
			# The file must still exist:
			return unless path = expand_path(record[:path])
			
			unless File.exist?(path)
				Console.logger.debug(self) {"Ignoring coverage, path #{path} does not exist!"}
				return
			end
			
			# If the file has been modified since... we can't use the coverage.
			return unless mtime = record[:mtime]
			
			unless ignore_mtime
				if File.mtime(path).to_f > record[:mtime]
					Console.logger.debug(self) {"Ignoring coverage, path #{path} has been updated: #{File.mtime(path).to_f} > #{record[:mtime]}!"}
					return
				end
			end
			
			record[:coverage].each_with_index do |count, index|
				@output.mark(path, index, count) if count
			end
		end
		
		def serialize(coverage)
			{
				# We want to use relative paths so that moving the repo won't break everything:
				path: relative_path(coverage.path),
				coverage: coverage.counts,
				mtime: File.mtime(coverage.path).to_f,
			}
		end
		
		def load!(**options)
			return unless File.exist?(@path)
			
			# Load existing coverage information and mark all files:
			File.open(@path, "rb") do |file|
				file.flock(File::LOCK_SH)
				
				Console.logger.debug(self) {"Loading from #{@path} with #{options}..."}
				
				make_unpacker(file).each do |record|
					self.apply(record, **options)
				end
			end
		end
		
		def save!
			# Dump all coverage:
			File.open(@path, "wb") do |file|
				file.flock(File::LOCK_EX)
				
				Console.logger.debug(self) {"Saving to #{@path}..."}
				
				packer = make_packer(file)
				
				self.each do |coverage|
					packer.write(serialize(coverage))
				end
				
				packer.flush
			end
		end
		
		def mark(file, line, count)
			@touched << file
			
			super
		end
		
		def enable
			super
			
			load!
		end
		
		def flush
			load!
			
			super
		end
		
		def disable
			super
			
			# @touched.each do |path|
			# 	if @output.accept?(path)
			# 		puts "Updated #{path} coverage."
			# 	end
			# end
			
			save!
		end
		
		# def each
		# 	super do |coverage|
		# 		if @touched.include?(coverage.path)
		# 			yield coverage
		# 		end
		# 	end
		# end
		
		def make_packer(io)
			packer = MessagePack::Packer.new(io)
			packer.register_type(0x00, Symbol, :to_msgpack_ext)
			packer.register_type(0x01, Time) {|object| object.to_s}
			
			return packer
		end
		
		def make_unpacker(io)
			unpacker = MessagePack::Unpacker.new(io)
			unpacker.register_type(0x00, Symbol, :from_msgpack_ext)
			unpacker.register_type(0x01, Time, :parse)
			
			return unpacker
		end
	end
end
