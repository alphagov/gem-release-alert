# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'
require 'octokit'

class HttpError < RuntimeError
end

class GemspecError < RuntimeError
end

class VersionChecker
  def fetch_all_govuk_gem_versions
    uri = URI("https://docs.publishing.service.gov.uk/gems.json")
    res = Net::HTTP.get_response(uri)

    raise HttpError unless res.is_a?(Net::HTTPSuccess)

    parsed_json = JSON.parse(res.body)
    govuk_gem_names = parsed_json.map { |gem| gem["app_name"] }

    govuk_versions = govuk_gem_names.map { |name| fetch_github_version(name) }.compact
    rubygems_versions = govuk_gem_names.map { |name| fetch_rubygems_version(name) }.compact
    puts govuk_versions
    puts rubygems_versions
  end

  def fetch_rubygems_version(gemname)
    uri = URI("https://rubygems.org/api/v1/gems/#{gemname}.json")
    res = Net::HTTP.get_response(uri)

    if res.is_a?(Net::HTTPSuccess)
      parsed_json = JSON.parse(res.body)
      parsed_json['version']
    end
  end

  def fetch_github_version(gemname)
    Dir.mktmpdir do |path|
      Dir.chdir(path) do
        clone_github_repo(gemname)
        gemspecs = Dir.glob("*.gemspec", base: gemname)
        if gemspecs.count == 1
          Gem::Specification::load("#{gemname}/#{gemspecs.first}").version.to_s
        else
          nil
        end
      end
    end
  end

  def clone_github_repo(name)
    `git clone --recursive --depth 1 --shallow-submodules git@github.com:alphagov/#{name}.git > /dev/null 2>&1`
  end

  def rubygems_and_github_match?(gemname)
    fetch_rubygems_version(gemname) == fetch_github_version(gemname)
  end
end
