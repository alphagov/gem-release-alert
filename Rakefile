require './lib/version_checker'

task default: %w[gem_release_alert]

task :gem_release_alert do
  VersionChecker.new.print_version_discrepancies
end
