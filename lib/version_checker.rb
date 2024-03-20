# frozen_string_literal: true

require "uri"
require "net/http"
require "json"
require "octokit"
require "slack/poster"

class HttpError < RuntimeError
end

class VersionChecker
  GEMS_API = URI("https://docs.publishing.service.gov.uk/gems.json")

  def slack_options(team)
    {
      icon_emoji: ":gem:",
      username: "Gem Release Bot",
      channel: team.to_s,
    }
  end

  def print_version_discrepancies
    all_govuk_gems.group_by { |gem| gem["team"] }.each do |team, gems|
      message = message_builder(gems)

      puts "team: #{team}\n#{message}"

      poster = Slack::Poster.new(ENV["SLACK_WEBHOOK"], slack_options(team))
      poster.send_message(message.to_s) unless message.empty?
    end
  end

  def message_builder(gems)
    gems.filter_map { |gem|
      repo_name = gem["app_name"]
      repo_url = gem["links"]["repo_url"]
      rubygems_version = fetch_rubygems_version(repo_name)
      if !rubygems_version.nil? &&
          files_changed_since_tag(repo_name, "v#{rubygems_version}").any? { |path| path_built_into_gem?(path) }
        "<#{repo_url}|#{repo_name}> has unreleased changes since v#{rubygems_version}"
      end
    }.join("\n")
  end

  def all_govuk_gems
    res = Net::HTTP.get_response(GEMS_API)
    if res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    else
      raise HttpError
    end
  end

  def fetch_rubygems_version(gem_name)
    uri = URI("https://rubygems.org/api/v1/gems/#{gem_name}.json")
    res = Net::HTTP.get_response(uri)

    JSON.parse(res.body)["version"] if res.is_a?(Net::HTTPSuccess)
  end

  def files_changed_since_tag(repo, tag)
    Dir.mktmpdir do |path|
      Dir.chdir(path) do
        if system("git clone --recursive --depth 1 --shallow-submodules --no-single-branch https://github.com/alphagov/#{repo}.git > /dev/null 2>&1")
          Dir.chdir(repo) do
            `git diff --name-only #{tag}`.split("\n")
          end
        else
          puts "Warning: Failed to clone #{repo}"
          []
        end
      end
    end
  end

  def path_built_into_gem?(path)
    path.start_with?("app/", "lib/") || path == "CHANGELOG.md"
  end
end
