$rubyforge_project = "'module import'"
$project = 'module-import'
$rcov_index_html = 'coverage/lib-module-import_rb.html'

require 'tasks/helpers'

def __DIR__; "#{File.dirname(__FILE__)}" end

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

require 'rubygems'
require 'spec/rake/spectask'

require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = $project
  s.rubyforge_project = $project
  s.version = "0.4.0"
  s.author = "Greg Weber"
  s.email = "greg@gregweber.info"
  s.homepage = "http://projects.gregweber.info/#{$project}"
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
<meta http-equiv="REFRESH" content="0;url=http://projects.gregweber.info/#{$project}"></head>
</html>
EOF
)
    end
    run "scp index.html gregwebs@rubyforge.org:/var/www/gforge-projects/#{$project}"
  end
end
