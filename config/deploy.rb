require "bundler/capistrano"
require 'capistrano/ext/multistage'

# staging
set :stages, ["testing"]
set :default_stage, "testing"

# application setting
set :application, "rally"
#set :repository,  "git@gitorious.autonavi.com:lucy/rally.git"
set :repository,  "git@github.com:lannier/rally.git"

set :keep_releases, 5

#setup rvm 2.0.0
set :rvm_ruby_string, '2.0.0@rally'
set :rvm_type, :system
set :rvm_bin_path, "/usr/local/rvm/bin"

require 'rvm/capistrano'

# settings
set :scm, :git
set :branch, "master"
#set :deploy_to, "/opt/rally"
set :deploy_to, "/var/www/rally"
#set :port, 25000

set :deploy_via, :remote_cache
#set :copy_dir, "tmp/rally.tar.gz"
#set :copy_dir, "/Users/autonavi/workspace/rally/"
#set :remote_copy_dir, "/tmp/rally.tar.gz"
#set :rails_pid, ""

# user
#set :user, "root"
#set :password, "PMO@autonavi.com"
#set :user, "susan"
#set :password, "liuweishan"
set :use_sudo, true

ssh_options[:forward_agent] = true


#server '10.19.1.135', :app, :web, :db, :primary => true
#server '192.168.1.137', :app, :web, :db, :primary => true

after "deploy", "deploy:cleanup"

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn_#{application} #{command}"
    end
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
    run "mkdir -p #{shared_path}/config"
    #put File.read("config/database.example.yml"), "#{shared_path}/config/database.yml"
    put File.read("config/database.yml"), "#{shared_path}/config/database.yml"
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end

  task :install_bundler do
    `gem install bundler`
  end
  #before "deploy", "deploy:check_revision"
  before "deploy:setup", "deploy:install_bundler"

  # Install RVM and Ruby before deploy
  #before "deploy:setup", "rvm:install_rvm"
  #before "deploy:setup", "rvm:install_ruby"


end





















