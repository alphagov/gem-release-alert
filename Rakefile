require "./lib/version_checker"

task default: %w[gem_release_alert]

desc "Checks for GOV.UK gems which have unreleased changes"
task :gem_release_alert do
  VersionChecker.new.print_version_discrepancies
end
