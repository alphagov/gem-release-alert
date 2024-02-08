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

    fetch_all_govuk_gems.each do |gem|
      repo_name = gem["app_name"]
      rubygems_version = fetch_rubygems_version(repo_name)
      if files_changed_since_tag(repo_name, "v" + rubygems_version).any? { |path| path_is_built_into_gem?(path) }
        discrepancies_found = true
        puts "#{repo_name} (owned by #{gem["team"]}) has unreleased changes since v#{rubygems_version}"
      end
    end

    unless discrepancies_found
      puts "No discrepancies found!"
    end
  end

  def fetch_all_govuk_gems
    uri = URI("https://docs.publishing.service.gov.uk/gems.json")
    res = Net::HTTP.get_response(uri)
    if res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    else
      raise HttpError
    end
  end

  def fetch_rubygems_version(gem_name)
    uri = URI("https://rubygems.org/api/v1/gems/#{gem_name}.json")
    res = Net::HTTP.get_response(uri)

    raise HttpError unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)['version']
  end

  def files_changed_since_tag(repo, tag)
    Dir.mktmpdir do |path|
      Dir.chdir(path) do
        `git clone --recursive --depth 1 --shallow-submodules --no-single-branch git@github.com:alphagov/#{repo}.git > /dev/null 2>&1`
        Dir.chdir(repo) do
          `git diff --name-only #{tag}`.split("\n")
        end
      end
    end
  end

  def path_is_built_into_gem?(path)
    path.end_with?(".gemspec") || path.start_with?("app/", "lib/")
  end
end
