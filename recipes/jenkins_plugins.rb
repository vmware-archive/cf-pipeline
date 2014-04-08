%w(
  git-client
  scm-api
  git
  parameterized-trigger
  ansicolor
  github-oauth
  github-api
  mailer
  envinject
  maven-plugin
  rebuild
).each do |plugin|
  jenkins_plugin plugin do
    action :install
  end
end
