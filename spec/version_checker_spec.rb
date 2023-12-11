# frozen_string_literal: true

require 'version_checker'
require 'base64'

RSpec.describe VersionChecker do
  it 'fetches version number of a gem from rubygems' do
    stub_rubygems_call('6.0.1')

    expect(subject.fetch_rubygems_version('govuk_app_config')).to eq('6.0.1')
  end

  it 'fetches version number of a gem from GitHub' do
    stub_github_call('9.7.0')

    expect(subject.fetch_github_version('govuk_app_config')).to eq('9.7.0')
  end

  it "compares versions of gems on GitHub and rubygems and it's a match" do
    stub_github_call('9.7.0')
    stub_rubygems_call('9.7.0')

    expect(subject.rubygems_and_github_match?('govuk_app_config')).to eq(true)
  end

  it "compares versions of gems on GitHub and rubygems and it's not a match" do
    stub_github_call('9.7.0')
    stub_rubygems_call('9.7.1')

    expect(subject.rubygems_and_github_match?('govuk_app_config')).to eq(false)
  end

  def stub_github_call(version)
    repo = { content: Base64.encode64(%(module GovukAppConfig\n  VERSION = "#{version}".freeze\nend\n)) }
    stub_request(:get, 'https://api.github.com/repos/alphagov/govuk_app_config/contents/lib/govuk_app_config/version.rb')
      .to_return(status: 200, body: repo.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_rubygems_call(version)
    repo = { "version": version }
    stub_request(:get, 'https://rubygems.org/api/v1/gems/govuk_app_config.json')
      .to_return(status: 200, body: repo.to_json, headers: {})
  end
end
