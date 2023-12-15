# frozen_string_literal: true

require 'version_checker'
require 'base64'

RSpec.describe VersionChecker do
  let(:example_gemspec_path) { File.join(__dir__, "example.gemspec") }

  it 'fetches version number of a gem from rubygems' do
    stub_rubygems_call('6.0.1')

    expect(subject.fetch_rubygems_version('example')).to eq('6.0.1')
  end

  it 'fetches version number of a gem from GitHub' do
    stub_github_call

    expect(subject.fetch_gemspec('example').version).to eq('1.2.3')
  end

  it "fetches gemspecs for all govuk repos" do
    stub_devdocs_call
    stub_github_call

    expect(subject.fetch_all_govuk_gemspecs).to eq([Gem::Specification.load(example_gemspec_path)])
  end

  it "detects when there are no version discrepancies" do
    stub_devdocs_call
    stub_github_call
    stub_rubygems_call('1.2.3')

    expect { subject.print_version_discrepancies }.to output("No discrepancies found!\n").to_stdout
  end

  it "detects when there are are version discrepancies" do
    stub_devdocs_call
    stub_github_call
    stub_rubygems_call('1.2.2')

    expect { subject.print_version_discrepancies }.to output(
      "Version mismatch for 'example':\n  Version on RubyGems: 1.2.2\n  Version on GitHub: 1.2.3\n"
    ).to_stdout
  end

  def stub_github_call
    allow(subject).to receive(:clone_github_repo) do
      FileUtils.mkdir "example"
      FileUtils.cp example_gemspec_path, File.join(Dir.pwd, "example")
    end
  end

  def stub_rubygems_call(version)
    repo = { "version": version }
    stub_request(:get, 'https://rubygems.org/api/v1/gems/example.json')
      .to_return(status: 200, body: repo.to_json, headers: {})
  end

  def stub_devdocs_call
    repo = [{ "app_name": "example" }]
    stub_request(:get, 'https://docs.publishing.service.gov.uk/gems.json')
      .to_return(status: 200, body: repo.to_json, headers: {})
  end
end
