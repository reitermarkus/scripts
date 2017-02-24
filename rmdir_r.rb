#!/usr/bin/env ruby

require 'pathname'
require 'fileutils'

class Pathname
  def rmdir_r
    paths = self.class.glob(join("**", "*"), File::FNM_DOTMATCH)
                      .sort_by { |p| -p.to_s.count(File::SEPARATOR) }

    if paths.all?(&:directory?)
      paths.map(&:expand_path).each(&:rmdir)
    else
      rmdir
    end
  end
end
