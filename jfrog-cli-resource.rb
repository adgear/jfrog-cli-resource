# frozen_string_literal: true
libs = Dir.glob('lib/*.rb')
libs.map { |l| require_relative(l) }
