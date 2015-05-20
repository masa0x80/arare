require 'thor'

module Arare
  class CLI < Thor
    option :license_db, default: '~/.arare.yml'
    option :install_path
    desc 'list', 'List up gem licenses.'
    def list(project_path)
      arare = Arare::List.new(project_path, options[:license_db], options[:install_path])
      puts arare.list.join("\n")
    end
  end
end
