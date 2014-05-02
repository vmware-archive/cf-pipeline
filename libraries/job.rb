module JenkinsClient
  class Job
    attr_accessor :artifact_glob,
                  :command,
                  :description,
                  :downstream_jobs,
                  :env,
                  :git_repo_url,
                  :git_repo_branch,
                  :builds_to_keep,
                  :build_parameters,
                  :block_on_downstream_builds

    def self.from_config(job_settings)
      new.tap do |job|
        job.command = 'run_user_script'
        job.env =
          {
            'PIPELINE_USER_SCRIPT' => job_settings.fetch('script_path')
          }.merge(job_settings.fetch('env', {}))

        job.git_repo_url = job_settings.fetch('git')
        job.git_repo_branch = job_settings.fetch('git_ref')

        job.downstream_jobs = job_settings.fetch('trigger_on_success', [])
        job.artifact_glob = job_settings.fetch('artifact_glob', nil)
        job.builds_to_keep = job_settings.fetch('builds_to_keep', nil)
        job.build_parameters = job_settings.fetch('build_parameters', [])
        job.block_on_downstream_builds = job_settings.fetch('block_on_downstream_builds', false)
        job.description = job_settings.fetch('description', nil)
      end
    end

    def initialize
      @downstream_jobs = []
      @env = {}
      @build_parameters = []
    end

    def to_xml
      require 'builder'
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.project do
        xml.description description
        xml.logRotator do
          xml.daysToKeep(-1)
          xml.numToKeep(builds_to_keep || -1)
          xml.artifactDaysToKeep(-1)
          xml.artifactNumToKeep(-1)
        end
        xml.blockBuildWhenDownstreamBuilding(!!block_on_downstream_builds)

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
      return if build_parameters.empty?
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
      xml.scm(class: 'hudson.plugins.git.GitSCM', plugin: 'git@2.1.0') do
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
          xml.propertiesContent(env.map { |k, v| "#{k}=#{v}" }.join("\n"))
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
