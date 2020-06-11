# frozen_string_literal: true

require 'grpc'

module GrpcMock
  class MockedCall
    attr_reader :deadline, :metadata

    def initialize(metadata: {})
      @metadata = MockedCall.sanitize_metadata(metadata)
      @deadline = Time.now + 5
    end

    def multi_req_view
      GRPC::ActiveCall::MultiReqView.new(self)
    end

    def single_req_view
      GRPC::ActiveCall::SingleReqView.new(self)
    end

    def self.sanitize_metadata(metadata)
      raise TypeError, "got <#{metadata.class}>, want <Hash>" unless metadata.is_a?(Hash)

      headers = []
      metadata.each do |key, value|
        raise TypeError, "bad type for key parameter" unless key.is_a?(String) || key.is_a?(Symbol)

        key = key.to_s
        raise ArgumentError, "'#{key}' is an invalid header key" unless key.match?(/\A[a-z0-9-_.]+\z/i)
        raise ArgumentError, "Header values must be of type string or array" unless value.is_a?(String) || value.is_a?(Array)

        Array(value).each do |elem|
          raise TypeError, "Header value must be of type string" unless elem.is_a?(String)

          unless key.end_with?('-bin')
            raise ArgumentError, "Header value '#{elem}' has invalid characters" unless elem.match(/\A[ -~]+\z/)

            elem = elem.strip
          end
          headers << [key, elem]
        end
      end

      metadata = {}
      headers.each do |key, elem|
        if metadata[key].nil?
          metadata[key] = elem
        elsif metadata[key].is_a?(Array)
          metadata[key] << elem
        else
          metadata[key] = [metadata[key], elem]
        end
      end

      metadata
    end
  end
end
