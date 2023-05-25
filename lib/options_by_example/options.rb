# frozen_string_literal: true


class OptionsByExample

  class Options

    attr_reader :arguments
    attr_reader :options

    def initialize(settings, arguments, options)
      @arguments = arguments
      @options = options

      [
        *settings.argument_names_required,
        *settings.argument_names_optional,
        *settings.option_names.values.select(&:last).map(&:first),
      ].each do |argument_name|
        instance_eval %{
          def argument_#{argument_name}
            val = @arguments[:#{argument_name}]
            val && block_given? ? (yield val) : val
          end
        }
      end

      settings.option_names.each_value do |option_name, _|
        instance_eval %{
          def include_#{option_name}?
            @options.include? :#{option_name}
          end
        }
      end
    end
  end
end
