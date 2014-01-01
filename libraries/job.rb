module JenkinsClient
  class Job
    attr_accessor :artifact_glob, :command, :description, :downstream_jobs, :git_repo_url, :git_repo_branch

    def downstream_jobs
      @downstream_jobs || []
    end

    def to_xml
      require 'builder'
      xml = Builder::XmlMarkup.new
      xml.project do
        xml.description description
        xml.builders do
          xml.tag! 'hudson.tasks.Shell' do
            xml.command command
          end
        end
        xml.scm(class: 'hudson.plugins.git.GitSCM', plugin: 'git@2.0') do
          xml.userRemoteConfigs do
            xml.tag!('hudson.plugins.git.UserRemoteConfig') do
              xml.url git_repo_url
            end
          end
          xml.branches do
            xml.tag!('hudson.plugins.git.BranchSpec') do
              xml.name git_repo_branch
            end
          end
        end

        xml.publishers do
          publish_downstream_jobs(xml, downstream_jobs)
          publish_artifacts(xml, artifact_glob)
        end

        xml.buildWrappers do
          xml.tag!('hudson.plugins.ansicolor.AnsiColorBuildWrapper', plugin: 'ansicolor@0.3.1') do
            xml.colorMapName 'xterm'
          end
        end
      end
    end

    private

    def publish_artifacts(xml, glob)
      return if glob.nil?
      xml.tag!("hudson.tasks.ArtifactArchiver") do
        xml.artifacts artifact_glob
        xml.latestOnly false
        xml.allowEmptyArchive false
      end
    end

    def publish_downstream_jobs(xml, jobs)
      return if jobs.empty?
      xml.tag!("hudson.plugins.parameterizedtrigger.BuildTrigger", plugin: "parameterized-trigger@2.22") do
        xml.configs do
          xml.tag!("hudson.plugins.parameterizedtrigger.BuildTriggerConfig") do
            xml.configs do
              xml.tag!("hudson.plugins.git.GitRevisionBuildParameters", plugin: "git@2.0") do
                xml.combineQueuedCommits false
              end
            end

            xml.projects jobs.join(', ')
            xml.condition "SUCCESS"
            xml.triggerWithNoParameters false
          end
        end
      end
    end
  end
end
