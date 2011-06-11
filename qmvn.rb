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

class MvnModule
  attr_reader :state, :leftover_lines, :log

  def initialize(line)
    @log = []
    @log << line

    @state = :header
    @leftover_lines = []
    @installed_artifacts = []
    @compiled_sources = 0
    @compiled_test_sources = 0
  end

  def parse(line)
    @log << line

    case line
    when /\[INFO\] --------------------/
      @state = case @state
               when :header
                 :body
               when :install_install
                 puts
                 @leftover_lines << @log.pop
                 :end
               else
                 :header
               end
    else
      case @state
      when :header
        if line[/\[INFO\] Building ([^\n]+)/]
          @artifact_name = $1
          print @artifact_name
        end
      when :body
        case line
        when /\[INFO\] \[compiler:compile/
          puts
          @state = :compiler
          @sub_state = :compile
        when /\[INFO\] \[compiler:testCompile/
          @state = :compiler
          @sub_state = :test_compile
        when /\[surefire:test/
          puts
          print '  executing tests'
        when /\[INFO\] \[install:install/
          puts
          @state = :install_install
        end
      when :compiler
        if line[/\[INFO\] Compiling (\d+) source files to/]
          case @sub_state
          when :compile
            @compiled_sources = $1
            print "  compiling: "
            print "#{@compiled_sources} sources"
          when :test_compile
            @compiled_test_sources = $1
            if @compiled_sources == 0
              print "  compiling: "
            else
              print ", "
            end
            print "#{@compiled_test_sources} test sources"
          end
          @state = :body
        end
      when :compiler_testCompile
        if line[/Compiling (\d+) source files to/]
          puts "  compiling #{$1} test sources"
          @state = :after_header
        end
      when :install_install
        if line[/Installing (.*?) to (.*)/]
          from_file = $1
          to_file = $2
          
          if @installed_artifacts.empty?
            print "  installing: #{File.basename(to_file)}"
          else
            print ", #{File.basename(to_file)}"
          end
          @installed_artifacts << to_file
        end
      end
    end
  end
end

modules = []
state = :reactor_build_order
current_module = nil

sub_state = :before
last_line = nil
ARGF.each do | line |
  case state
  when :reactor_build_order then
    sub_state = subsm_reactor_build_order(line, sub_state)
    if sub_state == :end
      state = :building_project
      sub_state = :inside_header
    end
  when :building_project
    if current_module == nil
      current_module = MvnModule.new(last_line)
    end
    
    current_module.parse(line)

    if current_module.state == :end
      #puts current_module.log
      modules << current_module
      current_module = nil
    end
  end
  last_line = line
end

# puts $reactor_build_order
