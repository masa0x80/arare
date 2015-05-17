require 'yaml'

module Arare
  class List
    UNKNOWN = 'Unknown'
    LICENSE_FILE_REGEXP_PATTERNS = %w[
      *license*
    ]

    def initialize(project_path, license_db, install_path)
      @license_db = {}
      @license_db = YAML.load_file(File.expand_path(license_db)) if File.exist?(File.expand_path(license_db))
      @project_path = File.expand_path(project_path)
      if install_path.class.to_s == 'String'
        @install_path = File.expand_path(install_path)
      else
        @install_path = File.join(@project_path, 'vendor/bundle/ruby/**/gems')
      end
      @installed_gem_versions = installed_gem_versions
    end

    def list
      @installed_gem_versions.keys.sort.each do |name|
        @installed_gem_versions[name].keys.each do |version|
          puts "#{name}\t#{version}\t#{@installed_gem_versions[name][version][:license]}\t#{@installed_gem_versions[name][version][:ref]}"
        end
      end
    end

    private
    def installed_gem_versions
      gems = {}
      filename_pattern = LICENSE_FILE_REGEXP_PATTERNS.join(',')
      Dir.glob(File.join(@install_path, '*')) do |gem_root|
        gem_root.split(File::SEPARATOR).last =~ /([a-z0-9_-]+)-([0-9.]+)/
        if @license_db.key?($1)
          gems[$1] ||= {$2 => {license: @license_db[$1][$2]['license'], ref: @license_db[$1][$2].fetch('ref', nil)}}
        else
          gems[$1] ||= {$2 => {license: UNKNOWN, ref: nil}}
        end
        Dir.glob(File.join(gem_root, "{#{filename_pattern}}"), File::FNM_CASEFOLD) do |license_file_path|
          license_file = license_file_path.split(File::SEPARATOR).last
          license = detect_license(license_file_path)
          gems[$1][$2] = {license: license, ref: license_file_path}
        end
      end
      gems
    end

    def detect_license(license_file_path)
      filename = license_file_path.split(File::SEPARATOR).last
      license = UNKNOWN
      if filename =~ /MIT-LICENSE/i
        license = 'MIT'
      end
      license
    end
  end
end
