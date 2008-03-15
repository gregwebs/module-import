rubyforge_project = "'module import'"
project = 'module-import'

def exit_msg(msg, code=1)
  puts msg
  exit(code)
end
def run command
  res = `#{command}`
  exit_msg res, $?.exitstatus if $?.exitstatus != 0
  res
end

def __DIR__; "#{File.dirname(__FILE__)}" end
class IO
  def self.write( file, str )
    self.open( file, 'w' ) { |fh| fh.print str }
  end
  def self.read_write( file, write_file=file )
    self.write(write_file, (yield( self.read( file ))))
  end
end

def cd_tmp
  Dir.mkdir 'tmp' unless File.directory? 'tmp'
  Dir.chdir('tmp') do |dir|
    yield dir
  end
  rm_rf 'tmp'
end

desc "test run all tests"
task :test => [:spec, 'test:readme', :rcov]

namespace :test do
  # run README through xmp
  desc "run README code through xmp filter"
  task :readme do
    cd_tmp do
      example_file = "#{__DIR__}/example.rb"

      File.write(example_file, (
        File.read("#{__DIR__}/lib/module-import.rb") << 
        File.readlines('../README').grep(/^  / ).
          reject {|l| l =~ /^\s*require/ or l.include?('Error')}.
            join ))

      command = "ruby ../bin/xmpfilter -c #{example_file}"
      Dir.chdir '/home/greg/src/head/lib' do
        run "#{command}"
      end
      puts "README code successfully evaluated"
    end
  end
end

desc "run specs"
task :spec do
  Dir[ 'spec/*' ].each do |file|
    (puts (run "spec #{file}"))
  end
end

require 'rubygems'
require 'spec/rake/spectask'

desc "verify test coverage with RCov"
task :rcov => 'rcov:verify'
namespace :rcov do
  Spec::Rake::SpecTask.new('rcov') do |t|
    t.spec_files = ['spec/*.rb']
    t.rcov = true
    t.rcov_opts = ['--exclude', 'spec']
  end

  require 'spec/rake/verify_rcov'
  # rcov is wrong- I am actually at 100%
  RCov::VerifyTask.new(:verify => :rcov) do |t|
    t.threshold = 100 # Make sure you have rcov 0.7 or higher!
    t.index_html = 'coverage/lib-module-import_rb.html'
  end
end

desc "release a new gem to rubyforge"
task :release => [:test,:record,:rdoc,:website,:package] do
  Dir.chdir('pkg') do
    release = Dir['*.gem'].sort_by {|file| File.mtime(file)}.last
    release =~ /^[^-]+-([.0-9]+).gem$/
    (puts (run `rubyforge login && rubyforge add_release #{project} #{project} #$1 #{release}`))
  end
end

desc "update website"
file :website => ['README','Rakefile'] do
  Dir.chdir '/home/greg/sites/projects/' do
    (puts (run 'rake projects:update'))
    (puts (run 'rake deploy:rsync'))
  end
end

desc "generate documentation"
task :rdoc do
  fail unless system 'rdoc --force-update --quiet README lib/*'
end

namespace :readme do
  desc "create html for website using coderay, use --silent option"
  task :html do
    rm_rf 'doc'
    `rdoc --quiet README`
    require 'hpricot'
    doc = open( 'doc/files/README.html' ) { |f| Hpricot(f) }
    # find example code
    doc.at('#description').search('pre').each do |ex|
      #select {|elem| elem.inner_html =~ /class |module /}.each do |ex|
      # add coderay and undo what rdoc has done in the example code
      ex.swap("<coderay lang='ruby'>#{ex.inner_html.gsub('&quot;', '"').gsub('&gt;','>')}</coderay>")
    end
    puts doc.at('#description').to_html
  end
end

desc 'git add and push'
task :record do
  unless `git diff`.chomp.empty?
    ARGV.clear
    puts "enter commit message"
    (puts (run "git commit -a -m '#{Kernel.gets}'"))
    puts "committed! now pushing.. "
    (puts (run 'git push origin master'))
  end
end

require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = project
  s.rubyforge_project = project
  s.version = "0.4.0"
  s.author = "Greg Weber"
  s.email = "greg@gregweber.info"
  s.homepage = "http://projects.gregweber.info/#{project}"
  s.platform = Gem::Platform::RUBY
  s.summary = "selectively import methods from modules"
  s.files = FileList.new('./**', '*/**') do |fl|
             fl.exclude('pkg','pkg/*','tmp','tmp/*')
           end
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = false
end

desc "run this once to set up the project"
task :setup do
  cd_tmp do
    unless File.exist? 'index.html'
      File.write('index.html', <<-EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html><head>
<meta http-equiv="REFRESH" content="0;url=http://projects.gregweber.info/#{project}"></head>
</html>
EOF
)
    end
    run "scp index.html gregwebs@rubyforge.org:/var/www/gforge-projects/#{project}"
  end
end
