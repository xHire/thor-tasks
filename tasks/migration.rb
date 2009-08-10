#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'rubygems'
require 'activerecord'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '../'))

class Db < Thor
  desc "migrate", "migrate the database"
  def migrate
    db_connection
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate File.join(ROOT, 'db', 'migrate')
  end

  protected
  def db_connection
    ActiveRecord::Base.logger = Logger.new STDOUT
    ActiveRecord::Base.establish_connection YAML.load_file(File.join(ROOT, 'config', 'database.yml'))
  end
end

class Generate < Thor
  method_options :table => false
  desc "migration NAME", "generate new migration template"
  def migration name
    # Get migration/table name
    if options[:table]
      table_name = name.strip.chomp
      migration_name = 'create_' + table_name
    else
      migration_name = name.strip.chomp
    end

    # Define migrations path
    migrations_path = File.join(ROOT, 'db', 'migrate')

    # Find the highest existing migration version or set to 1
    if (existing_migrations = Dir[File.join(migrations_path, '*.rb')]).length > 0
      version = File.basename(existing_migrations.sort.reverse.first)[/^(\d+)_/,1].to_i + 1
    else
      version = 1
    end

    migration_filename = "#{"%03d" % version}_#{migration_name}.rb"

    # Load the template
    if options[:table]
      migrations_template = File.read(File.join(migrations_path, 'migration_table.template'))

      migration_content = migrations_template.gsub('__migration_name__', migration_name.camelize)
      migration_content = migration_content.gsub('__table_name__', table_name.downcase)
    else
      migrations_template = File.read(File.join(migrations_path, 'migration.template'))

      migration_content = migrations_template.gsub('__migration_name__', migration_name.camelize)
    end

    # Write the migration
    File.open(File.join(migrations_path, migration_filename), "w") do |migration|
      migration.puts migration_content
    end

    # Done!
    say "Successfully created migration #{migration_filename}"
  end
end

# vim:sw=2:sts=2:et:filetype=ruby
