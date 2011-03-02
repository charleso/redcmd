VER = "0.3 (c) 2009 Dave Nolan textgoeshere.org.uk, github.com/textgoeshere/redcmd"
BANNER =<<-EOS
Red creates Redmine (http://www.redmine.org/) issues from the command line.

==Example==
Add an issue:

    red add -s "New feature" -d "Some longer description text" -t feature -p cashprinter -r high -a "Dave" -f /path/to/attachment
    # =>
    "Created Feature #999 New feature"
       
List some issues (you can reference a Redmine custom query here):
    
    red list 3
    # =>
    Fix widget
    Design thingy
    Document Windows 95 compatibility issues

Command line arguments override settings in the configuration file, which override Redmine form defaults.

==An example configuration file==
username: dave
password: d4ve
url: http://www.myredmineinstance.com
project: redcmd
tracker: bug
priorty: normal   

I recommend creating a configuration file per-project, and sticking it in your path.

# TODO: due, start, done, est. hours
# TODO: custom fields
# TODO: subcommands (list, update, etc.)

#{VER}

==Options==

EOS


begin
  require 'trollop'
  require 'mechanize'
  require 'uri'
rescue LoadError
  require 'rubygems'
  require 'trollop'
  require 'mechanize'
end

module Textgoeshere
  class RedmineError < StandardError; end
  
  class Red
    SELECTS = %w{priority tracker category assigned_to status fixed_version}
    
    def initialize(command, opts)
      @opts = opts
      @mech  = Mechanize.new
      login
      send(command)
    end
    
    private
    
    def login
      @mech.get login_url
      @mech.page.form_with(:action => /login/) do |f|
        f.field_with(:name => 'username').value = @opts[:username]
        f.field_with(:name => 'password').value = @opts[:password]
        f.click_button
      end
      catch_redmine_errors
    end
    
    def add
      @mech.get create_issue_action
      @mech.page.form_with(:action => create_issue_action) do |f|
        updatefields(f)
        puts "Created #{@mech.page.search('h2').text}: #{@opts[:subject]}"
      end
    end
    
    def updatefields(f)
        SELECTS.each do |name|
          value = @opts[name.to_sym]
          unless value.nil?
            field = f.field_with(:name => "issue[#{name}_id]")
            field.value = field.options.detect { |o| o.text.downcase =~ Regexp.new(value) }
            raise RedmineError.new("Cannot find #{name} #{value}") if field.value.nil? || field.value.empty?
          end
      end
        @opts[:subject] && f.field_with(:name => 'issue[subject]').value = @opts[:subject]
        @opts[:description] && f.field_with(:name => 'issue[description]').value = @opts[:description] || ""
        @opts[:notes] && f.field_with(:name => 'notes').value = @opts[:notes]
        (@opts[:file] || {}).each_with_index do |file, i|
          f.file_uploads_with(:name => "attachments[#{i.to_s()}][file]").first.file_name = file
        end
        if not @opts[:dryrun]
            f.click_button
            catch_redmine_errors
        end
    end
    
    def list
      @mech.get(list_issues_url)
      issues = @mech.page.parser.xpath('//table[@class="list issues"]/tbody//tr')
      if issues.empty?
        puts "No issues found at #{list_issues_url}"
      else
        @opts[:number].times do |i|
          issue = issues[i]
          break unless issue
          id = issue.xpath('td[@class="checkbox"]/input/@value')
          subject = issue.xpath('td[@class="subject"]/a').inner_html
          puts "\##{id}: #{subject}"
        end
      end
    end

    def versions
      @mech.get(create_issue_action)
       getformoptions('issue_fixed_version_id').each do |key, value|
            puts key
       end
    end
    
    def getformoptions(form_id)
        versions = @mech.page.parser.xpath("//select[@id='#{form_id}']/option")
        hash = {}
        versions.each do |version|
           hash[version.inner_html] = version['value']
        end
        hash.sort_by{|k,v| k}
    end
    
    def show
        @mech.get("#{pre}/issues/#{@opts[:id]}")
        content = @mech.page.parser.xpath('//div[@id="content"]')
        
        title = content.xpath('//h2').text + ": " + content.xpath('//div[2]/h3').text
        printline(title, '=')
        puts title
        printline(title, '=')
        puts
        
        content.xpath('//table[@class="attributes"]/tr').each do |tr|
            l1 = tr.xpath('th[1]').text + " " + tr.xpath('td[1]').text
            l2 = tr.xpath('th[2]').text + " " + tr.xpath('td[2]').text
            puts "#{l1.ljust(40)} #{l2}"
        end
        
        puts
        puts content.xpath("//textarea[@id='issue_description']").text
        
        @mech.page.parser.xpath("//div[@id='history']/div").each do |div|
            puts
            h4 = div.xpath("h4").text.gsub("\n", "").gsub("\t", "").gsub("        ", ": ")
            puts h4
            printline(h4, '-')
            if not div.xpath("ul/li").empty?
                puts
                puts div.xpath("ul/li[1]").text
                puts div.xpath("ul/li[2]").text
            end
            puts
            puts div.xpath("div//p").text
        end
    end
    
    def printline(string, char)
        string.each_char do |c|
            print char
        end
        puts
    end
    
    def update
        edit_url = "#{pre}/issues/#{@opts[:id]}/edit"
        @mech.get edit_url
        @mech.page.form_with(:action => edit_url) do |f|
            updatefields(f)
            puts @mech.page.search("//div[@id='content']/div[@class='flash notice']").inner_html
            puts @mech.page.search("//div[@id='errorExplanation']").inner_html
        end
    end
    
    def url; URI.split(@opts[:url])[0..4]; end
    def pre; URI.split(@opts[:url])[5]; end
    def login_action; '/login'; end
    def login_url; "#{@opts[:url]}#{login_action}"; end
      
    def create_issue_action; "#{pre}/projects/#{@opts[:project]}/issues/new"; end
    def list_issues_url
      params = @opts[:query_id] ? "?query_id=#{@opts[:query_id]}" : "" 
      "#{@opts[:url]}/projects/#{@opts[:project]}/issues#{params}"
    end
      
    def catch_redmine_errors
      error_flash = @mech.page.search('.flash.error')[0]
      raise RedmineError.new(error_flash.text) if error_flash
    end
  end
end

# NOTE: Trollop's default default for boolean values is false, not nil, so if extending to include boolean options ensure you explicity set :default => nil

COMMANDS = %w(add list show update)

global_options = Trollop::options do
  banner BANNER
  opt :username,    "Username",                     :type => String, :short => 'u'
  opt :password,    "Password",                     :type => String, :short => 'p'
  opt :url,         "Url to redmine",               :type => String
  opt :project,     "Project identifier",           :type => String
  opt :filename,    "Configuration file, YAML format, specifying default options.", 
          :type => String, :default => File.expand_path("~/.red")
  version VER
  stop_on COMMANDS
end

command = ARGV.shift
command_options = case command 
  when "add"
    Trollop::options do
      opt :subject, "Issue subject (title). This must be wrapped in inverted commas like this: \"My new feature\".", 
              :type => String, :required => true
      opt :description, "Description",                  :type => String
      opt :tracker,     "Tracker (bug, feature etc.)",  :type => String
      opt :assigned_to, "Assigned to",                  :type => String
      opt :priority,    "Priority",                     :type => String
      opt :status,      "Status",                       :type => String, :short => 'x'
      opt :category,    "Category",                     :type => String
      opt :dryrun,      "Dry-run",                      :short => 'n'
      opt :fixed_version,    "Target Version",       :type => String, :short => 'v'
      opt :file, 		    "File",                         :type => String, :multi => true
    end
  when "update"
    Trollop::options do
      opt :id,          "Id",                           :type => String, :required => true
      opt :assigned_to, "Assigned to",                  :type => String
      opt :priority,    "Priority",                     :type => String
      opt :status,      "Status",                       :type => String, :short => 'x'
      opt :category,    "Category",                     :type => String
      opt :dryrun,      "Dry-run"
      opt :notes,      "Notes",                         :type => String
      opt :fixed_version,    "Target Version",         :type => String, :short => 'v'
      opt :file, 		    "File",                         :type => String, :multi => true
  end
  when "list"
    Trollop::options do
      opt :number,     "Number of issues to display",   :type => Integer, :default => 5
      opt :query_id,   "Optional custom query id",      :type => Integer
  end
  when "versions"
    Trollop::options do
      opt :id, "Id",                  :id => String
    end
  when "show"
    Trollop::options do
      opt :id,          "Id",                           :type => String, :required => true
  end
  else
    Trollop::die "Uknown command #{command}"
end

opts = global_options.merge(command_options)
YAML::load_file(opts[:filename]).each_pair { |name, default| opts[name.to_sym] ||= default } if File.exist?(opts[:filename])
Textgoeshere::Red.new(command, opts)
