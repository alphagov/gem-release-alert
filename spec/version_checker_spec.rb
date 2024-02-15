# frozen_string_literal: true

require "version_checker"
require "base64"

RSpec.describe VersionChecker do
  subject(:version_checker) { described_class.new }

  it "fetches version number of a gem from rubygems" do
    stub_rubygems_call("6.0.1")

    expect(version_checker.fetch_rubygems_version("example")).to eq("6.0.1")
  end

  it "detects when there are no files changed since the last release that are built into the gem" do
    stub_devdocs_call
    stub_rubygems_call("1.2.3")
    stub_files_changed_since_tag(["README.md"])

    expect { version_checker.print_version_discrepancies }.to output("#platform-security-reliability-team\n\n").to_stdout
  end

  it "detects when there are files changed since the last release that are built into the gem" do
    stub_devdocs_call
    stub_rubygems_call("1.2.2")
    stub_files_changed_since_tag(["lib/foo.rb"])

    expect { version_checker.print_version_discrepancies }.to output(
      "#platform-security-reliability-team\n  example has unreleased changes since v1.2.2\n",
    ).to_stdout
  end

  # rubocop:disable RSpec/SubjectStub
  def stub_files_changed_since_tag(files)
    allow(version_checker).to receive(:files_changed_since_tag) do
      files
    end
  end
  # rubocop:enable RSpec/SubjectStub

  def stub_rubygems_call(version)
    repo = { "version": version }
    stub_request(:get, "https://rubygems.org/api/v1/gems/example.json")
      .to_return(status: 200, body: repo.to_json, headers: {})
  end

  def stub_devdocs_call
    repo = [{ "app_name": "example", "team": "#platform-security-reliability-team" }]
    stub_request(:get, "https://docs.publishing.service.gov.uk/gems.json")
      .to_return(status: 200, body: repo.to_json, headers: {})
  end
end
