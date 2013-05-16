# encoding: utf-8
require 'formatador'
require 'guard/guardfile/evaluator'
require 'guard/ui'

module Guard

  # The DSLDescriber overrides methods to create an internal structure
  # of the Guardfile that is used in some inspection utility methods
  # like the CLI commands `show` and `list`.
  #
  # @see Guard::DSL
  # @see Guard::CLI
  #
  class DSLDescriber

    attr_reader :options

    # Initializes a new DSLDescriber object.
    #
    # @option options [String] guardfile the path to a valid Guardfile
    # @option options [String] guardfile_contents a string representing the content of a valid Guardfile
    #
    # @see Guard::Guardfile::Evaluator#initialize
    #
    def initialize(options = {})
      @options = options
      ::Guard.options = { :plugin => [], :group => [] }
      ::Guard.reset_groups
      ::Guard.reset_guards
    end

    # List the Guard plugins that are available for use in your system and marks
    # those that are currently used in your `Guardfile`.
    #
    # @see CLI#list
    #
    def list
      _evaluate_guardfile

      rows = ::Guard::PluginUtil.plugin_names.sort.uniq.inject([]) do |rows, name|
        rows << { :Plugin => name.capitalize, :Guardfile => ::Guard.guards(name) ? '✔' : '✘' }
      end

      Formatador.display_compact_table(rows, [:Plugin, :Guardfile])
    end

    # Shows all Guard plugins and their options that are defined in
    # the `Guardfile`.
    #
    # @see CLI#show
    #
    def show
      _evaluate_guardfile

      rows = ::Guard.groups.inject([]) do |rows, group|
        Array(::Guard.guards({ :group => group.name })).each do |plugin|
          options = plugin.options.inject({}) { |o, (k, v)| o[k.to_s] = v; o }.sort

          if options.empty?
            rows << :split
            rows << { :Group => group.title, :Plugin => plugin.title, :Option => '', :Value => '' }
          else
            options.each_with_index do |(option, value), index|
              if index == 0
                rows << :split
                rows << { :Group => group.title, :Plugin => plugin.title, :Option => option.to_s, :Value => value.inspect }
              else
                rows << { :Group => '', :Plugin => '', :Option => option.to_s, :Value => value.inspect }
              end
            end
          end
        end

        rows
      end

      Formatador.display_compact_table(rows.drop(1), [:Group, :Plugin, :Option, :Value])
    end

    private

    def _evaluate_guardfile
      ::Guard::Guardfile::Evaluator.new(options).evaluate_guardfile
    end

  end
end
