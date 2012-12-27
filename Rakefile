require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yard do
    abort 'YARD is not available. In order to run yard, you must: gem install yard'
  end
end

require 'yaml'

def credentials
  @credentials ||= YAML.load_file File.expand_path(File.join(File.dirname(__FILE__), 'api_keys.yml'))
end

namespace :mailgun do
  require 'json'
  require 'rest-client'

  desc 'Create a Mailgun catch-all route forwarding to a postbin'
  task :postbin do

    bin_name = ENV['BIN_NAME'] || JSON.load(RestClient.post('http://requestb.in/api/v1/bins', {}))['name']
    bin_url  = "http://requestb.in/#{bin_name}"

    base_url = "https://api:#{credentials[:mailgun_api_key]}@api.mailgun.net/v2"
    action   = %(forward("#{bin_url}"))

    domain = ENV['DOMAIN'] || "#{SecureRandom.base64(4).tr('+/=lIO0', 'pqrsxyz')}.mailgun.com"

    if JSON.load(RestClient.get("#{base_url}/domains"))['items'].empty?
      puts "Creating the #{domain} domain..."
      RestClient.post("#{base_url}/domains", :name => domain)
    end

    route = JSON.load(RestClient.get("#{base_url}/routes"))['items'].find do |route|
      route['expression'] == 'catch_all()'
    end

    if route
      unless route['action'] == action
        puts "Updating the catch_all() route..."
        JSON.load(RestClient.put("#{base_url}/routes/#{route['id']}", :action => action))
      end
    else
        puts "Creating a catch_all() route..."
      JSON.load(RestClient.post("#{base_url}/routes", :expression => 'catch_all()', :action => action))
    end

    puts "#{bin_url}?inspect"
  end
end

namespace :mandrill do
  require 'mandrill'

  def mandrill_api
    @mandrill_api ||= Mandrill::API.new credentials[:mandrill_api_key]
  end

  def mandrill_domains
    @mandrill_domains ||= mandrill_api.inbound.domains.each_with_object({}) do |domain,domains|
      domains[domain['domain']] = domain
    end
  end

  def mandrill_domain
    @mandrill_domain ||= ENV['DOMAIN'] || mandrill_domains.keys.first
  end

  desc 'Create a Mandrill catch-all route forwarding to a postbin'
  task :validate do
    if mandrill_domains.empty?
      abort 'Add an inbound domain'
    elsif mandrill_domains.size > 1 && ENV['DOMAIN'].nil?
      abort "ENV['DOMAIN'] must be one of #{mandrill_domains.keys.join ', '}"
    end

    if ENV['DOMAIN'] && !mandrill_domains.keys.include?(ENV['DOMAIN'])
      abort "#{ENV['DOMAIN']} must be one of #{mandrill_domains.keys.join ', '}"
    end

    unless mandrill_domains[mandrill_domain]['valid_mx']
      puts "The MX for #{mandrill_domain} is not valid"
    end

    routes = mandrill_api.inbound.routes mandrill_domain
    if routes.empty? || routes.none?{|route| route['pattern'] == '*'}
      puts "Add a catchall (*) route for #{mandrill_domain}"
    end
  end
end
