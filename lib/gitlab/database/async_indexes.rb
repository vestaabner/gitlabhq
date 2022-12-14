# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      DEFAULT_INDEXES_PER_INVOCATION = 2

      def self.create_pending_indexes!(how_many: DEFAULT_INDEXES_PER_INVOCATION)
        PostgresAsyncIndex.to_create.order(:id).limit(how_many).each do |async_index|
          IndexCreator.new(async_index).perform
        end
      end

      def self.drop_pending_indexes!(how_many: DEFAULT_INDEXES_PER_INVOCATION)
        PostgresAsyncIndex.to_drop.order(:id).limit(how_many).each do |async_index|
          IndexDestructor.new(async_index).perform
        end
      end
    end
  end
end
