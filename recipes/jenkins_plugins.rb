%w(
  git-client
  scm-api
  git
  parameterized-trigger
  ansicolor
  github-oauth
  github-api
  mailer
).each do |plugin|
  jenkins_plugin plugin do
    action :install
  end
end
