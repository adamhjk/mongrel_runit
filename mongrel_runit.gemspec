(in /Users/adam/src/sandbox/mongrel_runit)
Gem::Specification.new do |s|
  s.name = %q{mongrel_runit}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Jacob"]
  s.date = %q{2008-09-10}
  s.default_executable = %q{mongrel_runit}
  s.description = %q{Use runit to manage a mongrel cluster}
  s.email = %q{adam@hjksolutions.com}
  s.executables = ["mongrel_runit"]
  s.extra_rdoc_files = ["CHANGELOG.txt", "History.txt", "Manifest.txt", "README.txt"]
  s.files = ["lib/mongrel_runit/base.rb", "lib/mongrel_runit/cli.rb", "lib/mongrel_runit/config.rb", "lib/mongrel_runit/service.rb", "lib/mongrel_runit/servicerunner.rb", "lib/mongrel_runit/version.rb", "lib/mongrel_runit.rb", "bin/mongrel_runit", "CHANGELOG.txt", "History.txt", "LICENSE", "Manifest.txt", "Rakefile", "README.txt", "test/config", "test/config/mongrel_runit.yml", "test/config/mongrel_runit_service.yml", "test/service", "test/sv", "test/tc_config.rb", "test/tc_service.rb", "test/tc_servicerunner.rb", "test/test_helper.rb", "test/test_mongrel_runit.rb", "test/testapp", "test/testapp/app", "test/testapp/app/controllers", "test/testapp/app/controllers/application.rb", "test/testapp/app/helpers", "test/testapp/app/helpers/application_helper.rb", "test/testapp/app/models", "test/testapp/app/views", "test/testapp/app/views/layouts", "test/testapp/components", "test/testapp/config", "test/testapp/config/boot.rb", "test/testapp/config/database.yml", "test/testapp/config/environment.rb", "test/testapp/config/environments", "test/testapp/config/environments/development.rb", "test/testapp/config/environments/production.rb", "test/testapp/config/environments/test.rb", "test/testapp/config/routes.rb", "test/testapp/db", "test/testapp/doc", "test/testapp/doc/README_FOR_APP", "test/testapp/lib", "test/testapp/lib/tasks", "test/testapp/log", "test/testapp/log/development.log", "test/testapp/log/production.log", "test/testapp/log/server.log", "test/testapp/log/test.log", "test/testapp/public", "test/testapp/public/404.html", "test/testapp/public/500.html", "test/testapp/public/dispatch.cgi", "test/testapp/public/dispatch.fcgi", "test/testapp/public/dispatch.rb", "test/testapp/public/favicon.ico", "test/testapp/public/images", "test/testapp/public/images/rails.png", "test/testapp/public/index.html", "test/testapp/public/javascripts", "test/testapp/public/javascripts/application.js", "test/testapp/public/javascripts/controls.js", "test/testapp/public/javascripts/dragdrop.js", "test/testapp/public/javascripts/effects.js", "test/testapp/public/javascripts/prototype.js", "test/testapp/public/robots.txt", "test/testapp/public/stylesheets", "test/testapp/Rakefile", "test/testapp/README", "test/testapp/script", "test/testapp/script/about", "test/testapp/script/breakpointer", "test/testapp/script/console", "test/testapp/script/destroy", "test/testapp/script/generate", "test/testapp/script/performance", "test/testapp/script/performance/benchmarker", "test/testapp/script/performance/profiler", "test/testapp/script/plugin", "test/testapp/script/process", "test/testapp/script/process/inspector", "test/testapp/script/process/reaper", "test/testapp/script/process/spawner", "test/testapp/script/runner", "test/testapp/script/server", "test/testapp/test", "test/testapp/test/fixtures", "test/testapp/test/functional", "test/testapp/test/integration", "test/testapp/test/mocks", "test/testapp/test/mocks/development", "test/testapp/test/mocks/test", "test/testapp/test/test_helper.rb", "test/testapp/test/unit", "test/testapp/tmp", "test/testapp/vendor", "test/testapp/vendor/plugins"]
  s.has_rdoc = true
  s.homepage = %q{https://wiki.hjksolutions.com/display/MR/Home}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mongrel_runit}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Use runit to manage a mongrel cluster}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
    else
    end
  else
  end
end
