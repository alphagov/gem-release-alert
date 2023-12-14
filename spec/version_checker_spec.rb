# frozen_string_literal: true

require 'version_checker'
require 'base64'

RSpec.describe VersionChecker do
  it 'fetches version number of a gem from rubygems' do
    stub_rubygems_call('6.0.1')

    expect(subject.fetch_rubygems_version('example')).to eq('6.0.1')
  end

  it 'fetches version number of a gem from GitHub' do
    stub_github_call

    expect(subject.fetch_github_version('example')).to eq('1.2.3')
  end

  it "compares versions of gems on GitHub and rubygems and it's a match" do
    stub_github_call
    stub_rubygems_call('1.2.3')

    expect(subject.rubygems_and_github_match?('example')).to eq(true)
  end

  it "compares versions of gems on GitHub and rubygems and it's not a match" do
    stub_github_call
    stub_rubygems_call('9.7.1')

    expect(subject.rubygems_and_github_match?('example')).to eq(false)
  end

  def stub_github_call
    allow(subject).to receive(:clone_github_repo) do
      FileUtils.mkdir "example"
      FileUtils.cp File.join(__dir__, "example.gemspec"), File.join(Dir.pwd, "example")
      # Copy a dummy gemspec into the current working directory.
    end
  end

  def stub_rubygems_call(version)
    repo = { "version": version }
    stub_request(:get, 'https://rubygems.org/api/v1/gems/example.json')
      .to_return(status: 200, body: repo.to_json, headers: {})
  end
end
