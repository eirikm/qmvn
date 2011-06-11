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
  ret_sub_state = sub_state
  
  case line
  when /--------------------/
    ret_sub_state = case sub_state
                    when :inside_header
                      :after_header
                    else
                      :inside_header
                    end
  else
    case sub_state
    when :inside_header
      case line
      when /Building ([^\n]+)/
        puts $1
      end
    when :after_header
      case line
      when /\[compiler:compile/
        puts '  compiling sources'
      when /\[compiler:testCompile/
        puts '  compiling test sources'
      when /\[surefire:test/
        puts '  executing tests'
      when /\[install:install/
        ret_sub_state = :install_install
      end
    when :install_install
      if line[/Installing (.*?) to (.*)/]
        from_file = $1
        to_file = $2
        
        puts "  installing: #{File.basename(to_file)}"
      end
    end
  end
  ret_sub_state
end


state = :reactor_build_order
sub_state = :before


ARGF.each do | line |
  case state
  when :reactor_build_order then
    sub_state = subsm_reactor_build_order(line, sub_state)
    if sub_state == :end
      state = :building_project
      sub_state = :inside_header
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
