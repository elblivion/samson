# frozen_string_literal: true
# deploys that automatically get triggered when new hosts come up or are restarted
class Api::AutomatedDeploysController < Api::BaseController
  STAGE_NAME = 'Automated Deploys'

  before_action :find_or_create_stage
  before_action :find_deploy_group
  before_action :find_last_deploy

  def create
    deploy_service = DeployService.new(current_user)
    env = params.require(:env).to_unsafe_hash.map { |k, v| "export PARAM_#{k}=#{v.shellescape}" }
    env << "export DEPLOY_GROUPS=#{@deploy_group.env_value}"

    deploy = deploy_service.deploy!(
      @stage,
      reference: @last_deploy.reference,
      buddy_id: @last_deploy.buddy_id,
      before_command: env.join("\n") << "\n"
    )

    if deploy.persisted? # TODO: also check that the deploy is running and not waiting for buddy
      render json: deploy.to_json, status: :created, location: [@stage.project, deploy]
    else
      failed! "Unable to start deploy: #{deploy.errors.full_messages}"
    end
  end

  private

  def find_or_create_stage
    project = Project.find_by_permalink!(params.require(:project_id))
    @stage = project.stages.where(name: STAGE_NAME).first || begin
      unless template = project.stages.where(is_template: true).first
        return failed! "Unable to find template for #{project.name}"
      end

      @stage = Stage.build_clone(template)
      @stage.name = STAGE_NAME
      unless @stage.save
        failed!("Unable to save stage: #{@stage.errors.full_messages}")
      end
      @stage
    end
  end

  def find_deploy_group
    @deploy_group = DeployGroup.find_by_permalink!(params.require(:deploy_group))
  end

  def find_last_deploy
    influencing_stages = DeployGroupsStage.where(deploy_group: @deploy_group).pluck(:stage_id)
    unless @last_deploy = Deploy.where(stage_id: influencing_stages).successful.last
      failed!("Unable to find successful deploy for #{@stage.name}")
    end
  end

  def failed!(message)
    render json: {error: message}, status: :bad_request
  end
end
