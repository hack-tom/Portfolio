# COM3420 Team 29 - Old

## Client E: Asset Management System

#### Zer Jun Eng, Alex Chapman, Wei Kin Khaw, Ritwesh

# Minimum System Requirements - Users

Operating System:
* Windows 7, Windows 8, Windows 8.1, Windows 10 or later
* Mac OS X Yosemite 10.10 or later
* 64-bit Ubuntu 14.04+, Debian 8+, openSUSE 13.3+, or Fedora Linux 24+

Web Browser:
* Chrome 65 or higher
* Firefox 59 or higher
* Opera 40 or higher
* Safari
* Microsoft Edge
* Internet Explorer is strongly not recommended

Network:
* Active internet connection required

# Software Requirements - Server
For this installation guide, we recommend installing the web application on a unix based server. For the purpose of this guide we will explain installation via cPanel, however the basic process explained in the following steps should be the same for other server control panels (even if there are slight differences in the exact procedure). If you are not sure how to proceed, contact the department's IT team, or the hosting provider’s support team.

* Unix Server Running cPanel (recommended)
* Ruby 2.3.1
* Rails 5.1.4
* Git
* OpenSSH
* PostGreSQL Database

# Installing Required Gems
## Installing Gems Via Bundler
If your web server does not already have bundler installed, then it is strongly recommended to do so. Open the terminal and run the following command:
`gem install bundler`

After that, navigate to the folder where Gemfile is stored, which should be the root of the project by default, and run the following command:
`bundle install`

You have now installed all system prerequisites, including the capistrano gem. This tool will help us set up the application quickly.

## Alternative: Manually Installing Gems
If for whatever reason, bundler is unavailable, the following gems and their dependencies should be installed before continuing you can do so using the command below:

`gem install [NAME OF THE GEM] -v [VERSION OF THE GEM]`

* 'rails', '5.1.4'
* 'responders'
* 'activerecord-session_store'
* 'thin'
* 'sqlite3'
* 'pg'
* 'haml-rails'
* 'sass-rails'
* 'uglifier'
* 'coffee-rails'
* 'jquery-rails'
* 'select2-rails'
* 'bootstrap-sass'
* 'epi_js'
* 'gon'
* 'simple_form'
* 'ransack', '~> 1.8.0'
* 'polyamorous', '~> 1.3.1'
* 'devise'
* 'devise_ldap_authenticatable'
* 'devise_cas_authenticatable'
* 'cancancan'
* "epi_cas"
* 'whenever'
* 'delayed_job'
* 'delayed_job_active_record'
* 'delayed-plugins-airbrake'
* 'daemons'
* 'carrierwave'
* 'rubyXL'
* 'multi_json', '~> 1.13', '>= 1.13.1'
* 'jbuilder', '~> 2.7'

Please follow guidance from your ISP on installing these gems for your specific web server if you are unsure how to do so.

# Deploying Application Manually
## Uploading Files To Server
For this guide we shall assume that Ruby and Ruby On Rails have been pre-installed on your web server. If this is not the case, please seek guidance on how to do this first.

Once Ruby and Ruby On Rails have been installed, click the file manager tab on your cPanel dashboard.

You should now see your server file tree. From here, press Extract and select root as the location where you want your unzipped files.

This should update the file structure such that the public_html folder contains /app, /config, /db, and all other files/folders.

## Setting Up Database and Seeding Data
The installation via capistrano outlined above should configure your database correctly. If you did not use capistrano to deploy the application, rake can be invoked directly to setup the database. Had the steps above been followed to invoke capistrano, the database will have already be correctly configured and created.

A rake task has been created to make the creation of your database as simple as possible. From the root directory of the rails application, run the following command:

`rake reset`

After running this command, the database will be created and an account for Erica Smith will be seeded to the database. Once this initial user has logged in, it is possible for her to create user accounts for all other users of the application.

You have now created both the database and the required seed data. No manual configuration was necessary.

# Deploying The Application Automatically
Deployment will ensure that all of the application’s files are not only sent to the right locations, but also that they are configured to work together properly. During deployment we recommend using GitHub or GitLab to store the application’s files. This will make deployment via capistrano much easier.
## Storing the project on GitHub
Please begin by creating a github account at https://github.com/join. Following this, you must create a repository, which stores the application files by pressing New Repository on the homepage and filling out the following form. Once happy with the repository, use the provided instructions to upload and unpacked the zipped code.
## Alternative: Storing the project on GitLab
Alternatively you can store the application on GitLab. If you do not already have an account, create one at https://gitlab.com/users/sign_in. Now create a repository. As explained in GitHub instructions, this is where we will store the application files.
## Deployment Prerequisites
To deploy the project we will first need to amend capistrano’s configuration files to ensure the application is deployed to the correct place. First navigate to config/deploy.rb and update the following lines:

```
set :repo_url,    'Repository URL'
set :application, 'Application Name'
```

Repository URL should be the url of the repository you created and unzipped the application files to.
Application Name should be your chosen name for the application.

Now navigate to config/deploy/demo.rb and update the following lines.

```
## Application deployment configuration
set :server,      'epi-stu-hut-demo4.shef.ac.uk'
set :user,        'demo.team29'
set :deploy_to,   -> { "/srv/services/#{fetch(:user)}" }
set :log_level,   :debug

## Server configuration
server fetch(:server), user: fetch(:user), roles: %w[web app db]

## Additional tasks
namespace :deploy do
  task :seed do
    on primary :db do
      within current_path do
                        with rails_env: fetch(:stage) do
                          execute :rake, 'db:seed'
                        end end end
  end
end
```

Once done, you can update the repository to save the configuration changed. To do this run the following commands on the console:
`git add -A`
`git commit -m "Config Updated"`
`git push -u origin master`

We are now ready to deploy the application and can do so using the epiDeploy gem if this is available for use. Alternatively, a guide has been provided for using solely capistrano to deploy, without the aid of epiDeploy.

## Deployment Via epiDeploy
The epiDeploy gem may not be available as it was developed within epiGenesys to facilitate the work of students, rather than for commercial use. If available, you can easily deploy the project using the terminal using the command:
`bundle exec ed release -d demo`
This command invokes capistrano and seeds the initial user to the system once it is ready.
## Alternative: Deployment Via Capistrano
If the epiDeploy gem is not available, you can manually deploy the software to your web server via the capistrano dem. The epiDeploy method also uses this gem for deployment, however as it is unavailable or you have chosen to not use it, we must invoke it manually.

To do this, use the command:

`bundle exec cap demo deploy:seed`

The above will deploy the system and run a rake task which automatically seeds data to the database, needed to let the initial user log in.

# Initialising The System
## Updating Seed Users
If you wish to change which users are created when the system is deployed, navigate to /db/seeds.rb.
Under the list of automatically created users, you can add or remove user’s which should be created automatically when the system is deployed. To delete a seed user, simply delete the entry. To add a user add the following line:
`User.create(email: '{MUSE Email}'', givenname: '{First Name}', sn: '{Surname}', permission_id: {Permission Level 1/2/3}, username: '{Muse Username}')`
## Creating Administrators
Now that the system has been configured you should be able to access it at your designated web server address. Please refer to the user manual for guidance on how to create user accounts for other administrators or other types of user. There are designated sections within the user manual for each of these.
