Description
===========

Bootstrap recipes for Rails apps deployed by capistrano. Foreman is used to
create daemons.

Only upstart is supported, should also support runit in future.

Requirements
============

Require gem 'foreman' on nodes.

Attributes
==========

-   `node['rails_capistrano_foreman']['formatter']`: Choose foreman formatter
-   `node['rails_capistrano_foreman']['location']`: Choose foreman export location
-   `node['rails_capistrano_foreman']['application']`: Application name
-   `node['rails_capistrano_foreman']['deploy_to']`: Where the Rails app is
    deployed to. It is "/u/apps/#{application}" by default in capistrano.
-   `node['rails_capistrano_foreman']['user']`: The user used in capistrano to deploy.
-   `node['rails_capistrano_foreman']['group']`: Group the user belongs to.
-   `node['rails_capistrano_foreman']['keys']`: Array of public keys that should
    be saved to `authorized_keys`.
    
    
        node.set['rails_capistrano_foreman']['keys] = [
          "ssh-rsa AAA.....",
          "ssh-rsa AAA....."
        ]

-   `node['rails_capistrano_foreman']['force_keys']`: Regenerate
    `authorized_keys`, by default, it is only created when user has no such
    file yet.

-   `node['rails_capistrano_foreman']['procfile']`: A hash, which is saved as
    Procfile by convert it to yaml.
    
    
        node.set['rails_capistrano_foreman']['procfile'] = {
          'web' => 'bundle exec rails server -p $PORT',
          'worker' => 'bundle exec sidekiq -c $SIDEKIQ_CONCURRENCY'
        }
    
-   `node['rails_capistrano_foreman']['concurrency']`: Optional, can specify
    concurrency of each process in Procfile. (corresponding to `--concurrency` in
    foreman export)

        node.set['rails_capistrano_foreman']['concurrency'] = "web=2,worker=1"

-   `node['rails_capistrano_foreman']['env']`: A hash of environment variables
    that will be exported to processes in Procfile. (corresponding to `--env` in
    foreman export)

        node.set['rails_capistrano_foreman']['env'] = {
          'RAILS_ENV' => 'production',
          'SIDEKIQ_CONCURRENCY' => 10
        }

-   `node['rails_capistrano_foreman']['port']`: foreman start port.

Usage
=====

Include recipe directly

    include_recipe 'rails_capistrano_foreman'

Or use the resource, the attributes can be set by method:

    rails_capistrano_foreman 'app_name' do
      application 'app_name'
      deploy_to '/u/apps/app_name'
      ...
      action :install
    end

To remove the installed files, use action `:remove`.

