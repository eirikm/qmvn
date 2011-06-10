#!/usr/bin/env ruby

$reactor_build_order = []

# sub state machine for reactor_build_order
def subsm_reactor_build_order(line, sub_state)
  def extract_project_name(line)
    line[9..-1].chop
  end
  
  case sub_state
  when :before then
    if line[/Reactor build order:/]
      :start
    else
      :before
    end
  when :start then
    if line[/------------------------------------------------------------------------/]
      :end
    else
      $reactor_build_order << extract_project_name(line)
      :start
    end
  end
end

def subsm_building_project(line, sub_state)
  case line
  when /Building ([^\n]+)/
    puts $1
  when /\[compiler:compile/
    :compiler_compile
  when /\[compiler:testCompile/
    :compiler_testCompile
  when /\[install:install/
    :install_install
  else
    case sub_state
    when :compiler_compile
      if line[/Compiling (\d+) source files/]
        puts "Compiling #{$1} files"
      end
    when :compiler_testCompile
      if line[/Compiling (\d+) source files/]
        puts "Compiling #{$1} test files"
      end
    when :install_install
      puts line
      :end
    end
  end
end


state = :reactor_build_order
sub_state = :before


ARGF.each do | line |
  case state
  when :reactor_build_order then
    sub_state = subsm_reactor_build_order(line, sub_state)
    if sub_state == :end
      state = :building_project
      sub_state = :start
    end
  when :building_project
    sub_state = subsm_building_project(line, sub_state)
    if sub_state == :end
      state = :building_project
      sub_state = :start
    end
  end
end

# puts $reactor_build_order
