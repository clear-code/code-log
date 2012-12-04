#!/usr/bin/env ruby
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "net/http"
require "json"

module CodeLog
  module Crawlers
    class GitHub
      attr_reader :poll_interval
      def initialize
        @etag = nil
        @poll_interval = 60
        @rate_limit_limit = nil
      end

      def crawl(&block)
        Net::HTTP.start("api.github.com", :use_ssl => true) do |http|
          http.set_debug_output $stderr
          request_header = {}
          request_header["If-None-Match"] = "\"#{@etag}\"" if @etag
          response = http.get("/users/kou/events", request_header)
          process_response(response, &block)
        end
      end

      private
      def process_response(response, &block)
        collect_header_info(response)

        case response
        when Net::HTTPOK
          @etag = response["ETag"]
          JSON.parse(response.body).each(&block)
        when Net::HTTPNotModified
          # do nothing
        else
          puts(response)
          puts(response.body)
        end
      end

      def collect_header_info(response)
        @poll_interval = Integer(response["X-Poll-Interval"] || @poll_interval)
      end
    end
  end
end
