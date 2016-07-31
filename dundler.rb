#!/usr/bin/env ruby
require "bundler"
require "bundler/lockfile_parser"

b = Bundler::LockfileParser.new(File.read("Gemfile.lock"))

gl_contents = File.read("Gemfile.lock")
existing_dependencies = []
dep_block = ""

NEW_FILE = "Dockerfile.dundler"
OLD_FILE = ".Dockerfile.dundler.old"

if File.exist?(NEW_FILE)
  `cp #{NEW_FILE} #{OLD_FILE}`
end

if File.exist?(OLD_FILE)
  dundler_contents = File.read(OLD_FILE)
  dep_lines = dundler_contents.each_line.select { |x| /RUN gem install/ === x }
  existing_dependencies = dep_lines.map {|x| x.split(" ")[3].strip}
  dep_block = dep_lines.join("")
end

p existing_dependencies


build = b.dependencies.reject { |x| existing_dependencies.include?(x.name) }.sort_by { |item|
  name = item.name
  count = -1 * (gl_contents.scan(/#{name}/).count)

  count
}.map { |x|
  if b.specs.map(&:name).include?(x.name)
    "RUN gem install #{x.name} -v #{b.specs.find { |y| y.name == x.name}.version.to_s}"
  else
    nil
  end
}.compact.join("\n")

dockerfile_in = File.open("Dockerfile", "r")
dockerfile_out = File.open(NEW_FILE, "w")

dockerfile_in.read.each_line do |l|
  if /(ADD|COPY) Gemfile / === l
    dockerfile_out.write(dep_block)
    dockerfile_out.write(build)
    dockerfile_out.write("\n")
  end

  dockerfile_out.write(l)
end

dockerfile_out.close
