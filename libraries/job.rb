module JenkinsClient
  class Job
    attr_accessor :artifact_glob, :command, :description, :downstream_jobs, :env, :git_repo_url, :git_repo_branch, :build_parameters

    def initialize
      @downstream_jobs = []
      @env = {}
      @build_parameters = []
    end

    def to_xml
      require 'builder'
      xml = Builder::XmlMarkup.new
      xml.project do
        xml.description description

        properties(xml)

        xml.builders do
          xml.tag! 'hudson.tasks.Shell' do
            xml.command command
          end
        end

        scm(xml)

        xml.publishers do
          publish_downstream_jobs(xml, downstream_jobs)
          publish_artifacts(xml, artifact_glob)
        end

        xml.buildWrappers do
          build_wrappers(xml)
        end
      end
    end

    private

    def properties(xml)
      xml.properties do
        xml.tag!('hudson.model.ParametersDefinitionProperty') do
          xml.parameterDefinitions do
            build_parameters.each do |param|
              xml.tag!('hudson.model.StringParameterDefinition') do
                xml.name param['name']
                xml.description param['description']
              end
            end
          end
        end
      end
    end

    def scm(xml)
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
    end

    def build_wrappers(xml)
      xml.tag!('hudson.plugins.ansicolor.AnsiColorBuildWrapper', plugin: 'ansicolor@0.3.1') do
        xml.colorMapName 'xterm'
      end

      xml.EnvInjectBuildWrapper(plugin: 'envinject@1.89') do
        xml.info do
          xml.propertiesContent(env.map {|k, v| "#{k}=#{v}"}.join("\n"))
          xml.loadFilesFromMaster(false)
        end
      end
    end

    def publish_artifacts(xml, glob)
      return if glob.nil?
      xml.tag!('hudson.tasks.ArtifactArchiver') do
        xml.artifacts artifact_glob
        xml.latestOnly false
        xml.allowEmptyArchive false
      end
    end

    def publish_downstream_jobs(xml, jobs)
      return if jobs.empty?
      jobs.each do |job|
        if job.is_a?(String)
          job = {'name' => job}
        end

        xml.tag!('hudson.plugins.parameterizedtrigger.BuildTrigger', plugin: 'parameterized-trigger@2.22') do
          xml.configs do
            xml.tag!('hudson.plugins.parameterizedtrigger.BuildTriggerConfig') do
              xml.configs do
                xml.tag!('hudson.plugins.git.GitRevisionBuildParameters', plugin: 'git@2.0') do
                  xml.combineQueuedCommits false
                end

                if job['parameters']
                  xml.tag!('hudson.plugins.parameterizedtrigger.PredefinedBuildParameters') do
                    xml.properties do
                      xml.cdata!(job['parameters'])
                    end
                  end
                end
              end

              xml.projects job['name']
              xml.condition 'SUCCESS'
              xml.triggerWithNoParameters(!job['parameters'])
            end
          end
        end
      end
    end
  end
end
