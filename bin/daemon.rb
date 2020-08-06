#!/bin/env ruby

require 'daemons'

Daemons.run_proc('rmud', backtrace: true) do |d|
  puts d.inspect

  Signal.trap 'EXIT' do
    puts "C EXIT"
  end

  Signal.trap 'QUIT' do
    puts "C QUIT"
  end

  Signal.trap 'TERM' do
    puts "C TERM"
  end

  5.times do |i|
    STDOUT.puts "STDOUT loop #{i}"
    STDERR.puts "STDERR loop #{i}"
    sleep 3
  end
end

exec('tt++')