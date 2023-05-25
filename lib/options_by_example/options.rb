# frozen_string_literal: true


class OptionsByExample

  class Options

    def initialize(settings, values)
      @values = values

      [
        *settings.argument_names_required,
        *settings.argument_names_optional,
        *settings.option_names.values.select(&:last).map(&:first),
      ].each do |argument_name|
        instance_eval %{
          def argument_#{argument_name}
            val = @values[:#{argument_name}]
            val && block_given? ? (yield val) : val
          end
        }
      end

      settings.option_names.each_value do |option_name, _|
        instance_eval %{
          def include_#{option_name}?
            @values.include? :#{option_name}
          end
        }
      end
    end

    def to_h
      @values.dup
    end
  end
end
