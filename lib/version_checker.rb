# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'
require 'octokit'

class HttpError < RuntimeError
end

class VersionChecker
  def fetch_rubygems_version(gemname)
    uri = URI("https://rubygems.org/api/v1/gems/#{gemname}.json")
    res = Net::HTTP.get_response(uri)

    raise HttpError unless res.is_a?(Net::HTTPSuccess)

    parsed_json = JSON.parse(res.body)
    parsed_json['version']
  end

  def fetch_github_version(gemname)
    payload = Octokit.contents("alphagov/#{gemname}", path: "lib/#{gemname}/version.rb")
    Base64.decode64(payload[:content]).split('"')[1]
  end

  def rubygems_and_github_match?(gemname)
    fetch_rubygems_version(gemname) == fetch_github_version(gemname)
  end
end
