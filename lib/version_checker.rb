# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'
require 'octokit'

class HttpError < RuntimeError
end

class VersionChecker
  def print_version_discrepancies
    discrepancies_found = false

    fetch_all_govuk_gemspecs.each do |gemspec|
      rubygems_version = fetch_rubygems_version(gemspec.name)
      unless gemspec.version == rubygems_version
        discrepancies_found = true
        puts "Version mismatch for '#{gemspec.name}':"
        puts "  Version on RubyGems: #{rubygems_version}"
        puts "  Version on GitHub: #{gemspec.version}"
      end
    end

    unless discrepancies_found
      puts "No discrepancies found!"
    end
  end

  def fetch_all_govuk_gemspecs
    uri = URI("https://docs.publishing.service.gov.uk/gems.json")
    res = Net::HTTP.get_response(uri)

    raise HttpError unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
      .map { |gem| fetch_gemspec(gem["app_name"]) }
      .compact
  end

  def fetch_rubygems_version(gem_name)
    uri = URI("https://rubygems.org/api/v1/gems/#{gem_name}.json")
    res = Net::HTTP.get_response(uri)

    raise HttpError unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)['version']
  end

  def fetch_gemspec(repo_name)
    Dir.mktmpdir do |path|
      Dir.chdir(path) do
        clone_github_repo(repo_name)
        gemspecs = Dir.glob("*.gemspec", base: repo_name)
        if gemspecs.count == 1
          Gem::Specification::load("#{repo_name}/#{gemspecs.first}")
        else
          nil
        end
      end
    end
  end

  def clone_github_repo(name)
    `git clone --recursive --depth 1 --shallow-submodules git@github.com:alphagov/#{name}.git > /dev/null 2>&1`
  end
end
