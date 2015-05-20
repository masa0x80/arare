require 'yaml'

module Arare
  class List
    UNKNOWN = 'Unknown'
    LICENSE_FILE_REGEXP_PATTERNS = %w[
      *license*
      *licence*
      *copying*
      *readme*
    ]

    def initialize(project_path, license_db, install_path)
      @license_db = {}
      @license_db = YAML.load_file(File.expand_path(license_db)) if File.exist?(File.expand_path(license_db))
      @project_path = File.expand_path(project_path)
      if install_path.class.to_s == 'String'
        @install_path = File.expand_path(install_path)
      else
        @install_path = File.join(@project_path, 'vendor/bundle/ruby/*/gems')
      end
      @installed_gem_versions = installed_gem_versions
    end

    def list
      result = []
      @installed_gem_versions.keys.sort.each do |name|
        @installed_gem_versions[name].keys.each do |version|
          result.push "#{name}\t#{version}\t#{@installed_gem_versions[name][version][:license]}\t#{@installed_gem_versions[name][version][:ref]}"
        end
      end
      result
    end

    private
    def installed_gem_versions
      gems = {}
      filename_pattern = LICENSE_FILE_REGEXP_PATTERNS.join(',')
      Dir.glob(File.join(@install_path, '*')) do |gem_root|
        gem_root.split(File::SEPARATOR).last =~ /([a-z0-9_-]+)-([0-9.]+)/
        gems[$1] ||= {$2 => {license: UNKNOWN, ref: nil}}
        gems[$1][$2] = {license: @license_db[$1][$2]['license'], ref: @license_db[$1][$2].fetch('ref', nil)} if @license_db.key?($1)
        next unless gems[$1][$2][:license] == UNKNOWN
        Dir.glob(File.join(gem_root, "{#{filename_pattern}}"), File::FNM_CASEFOLD) do |license_file_path|
          next unless gems[$1][$2][:license] == UNKNOWN
          license = detect_license(license_file_path)
          gems[$1][$2] = {license: license, ref: license_file_path} unless license == UNKNOWN
        end
      end
      gems
    end

    def detect_license(license_file_path)
      Dir.glob(File.expand_path('../../../templates/*/*', __FILE__)) do |file|
        r = Regexp.compile(read_and_normalize(file).gsub(/\(/, '\\(').gsub(/\)/, '\\)'))
        return File.dirname(file).split(File::SEPARATOR).last if r.match(read_and_normalize(license_file_path))
      end
      return UNKNOWN
    end

    def read_and_normalize(file_path)
      text = File.read(file_path).strip
      text.strip.gsub!(/\n/, ' ').gsub!(/[ ]{2,}/, ' ')
    end
  end
end
