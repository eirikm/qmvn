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
    puts "k"
  end
end

puts $reactor_build_order
