# frozen_string_literal: true

module SimpleEndpoint
  module Controller
    class Builder
      def initialize(&block)
        @config = {}
        instance_exec(&block)
      end

      def to_h
        @config
      end

      private

      def on(key, &block)
        @config[key] = block
      end

      alias match on
    end
  end
end
